#!/usr/bin/perl

my $usage="
# mergeAssemliesBasedOnNucmer.pl
# written by Linnéa Smeds                       12 Nov 2017
# =========================================================
# Takes a list of adjacent subcontigs which ends aligns to
# the same query contig (=bridged gaps). Non adjacent sub-
# contigs are allowed if alignment to the subcontig(s) 
# between them is missing (=should be removed/replaced by
# sequence from the query contig). 
# Outputs a new fasta file with closed gaps, and a list
# with all the changes made. 
#
# Needed input: 
# *Alignment file described above
# *bed file over the subcontigs and gaps, using names sub000X, gap000X
# *fasta files of both query and subcontig


# =========================================================
";

use strict;
use warnings;
use List::Util qw[min max];


# INPUT PARAMETERS
my $ALIGN = $ARGV[0];	#left_target_name, ltstart, ltend, qstart, qend, ident, query_contig, rtstart, rtend, qstart, qend, ident, right_target_name
my $BED = $ARGV[1];
my $TFASTA = $ARGV[2];
my $QFASTA = $ARGV[3];
my $OUTPREF = $ARGV[4];

# DERIVED VARIABLES
my $TLEN=$TFASTA.".fai";
my $out=$OUTPREF.".closed.bed";		# bed output
my $outfa=$OUTPREF.".closed.fasta";	# fasta output
my %subcon=();						# hash table for storing alignment info 
my $seq="";							# where new sequence is stored


# CHECK INPUT AND FILES
unless($ALIGN) {
	die $usage;
}
unless(-e $ALIGN) {
	die "Can't find alignment file $ALIGN!\n";
}
unless(-e $TFASTA) {
	die "Can't find subcontig fasta file $TFASTA!\n";
}
unless(-e $TLEN) {
	die "Can't find fasta index file $TLEN! Create it with samtools faidx!\n";
}

unless(-e $QFASTA) {
	die "Can't find query fasta file $QFASTA!\n";
}


# SAVE SUB CONTIG LENGTHS
my %tlen=();
open(IN, $TLEN);
while(<IN>) {
	my @t=split(/\s+/, $_);
	$tlen{$t[0]}=$t[1];
}
close(IN);


# OPEN THE BED OUTPUT FILEHANDLE
open(OUT, ">$out"); 
# OPEN THE ALIGNMENT ("bridge") FILE
open(IN, $ALIGN);
while(<IN>) {
	my @t=split(/\s+/, $_);

	my $ovl="0";
	my $badflag="no";
	my $end=$t[2];
	my $start=0;
	my ($addbetween, $addst, $addend) = ("","","");
	my $qdir="";

#	print STDERR "DEBUG PART1: Looking at ".$t[0]."-".$t[12]."\n";

	# If query contig aligns reverse on the left side, check that it also aligns
	# reverse on the right side
	if($t[3]>$t[4]) {
		if($t[9]<$t[10]) {
			print STDERR "WARNING: ".$t[0]."-".$t[12].": Query ".$t[6]." aligns in two different directions! Cannot close gap\n";
			$badflag="yes";
		}
		# If left and right alignments are overlapping, save overlap length
		if($t[4]<=$t[9]) {	
			$ovl=$t[9]-$t[4]+1;

			# If they are not only overlapping, but the right subcontigs
			# aligns to the left of the left subcontig:
			if($t[4]<=$t[10]) {
				print STDERR "WARNING: Right contig ".$t[12]." aligns to the left of ".$t[0]."! Please check alignment.\n";
				$badflag="yes";
			}
		}
		$qdir="-";
	}
	# Query aligns in positive direction
	else {
		if($t[9]>$t[10]) {
			print STDERR "WARNING: ".$t[0]."-".$t[12].": Query ".$t[6]." aligns in two different directions! Cannot close gap\n";
			$badflag="yes";
		}
		# Save overlap
		if($t[4]>=$t[9]) {
			$ovl=$t[4]-$t[9]+1;

			if($t[4]>=$t[10]) {
				print STDERR "WARNING: Right contig ".$t[12]." aligns to the left of ".$t[0]."! Please check alignment.\n";
				$badflag="yes";
			}
		}
		$qdir="+";
	}

	# Only proceed if the left and right query 
	# alignments had the same orientation
	unless($badflag eq "yes") {

		# Check if the gaps are adjacent
		my $left=$t[0];
		$left=~s/sub//;
		my $right=$t[12];
		$right=~s/sub//;
		my $diff=$right-$left;

#		print STDERR "\tleft is $left and right is $right and diff is $diff\n";

		# There are subcontigs in between, save them in the hash
		if($right-$left>1) {	
			$subcon{$t[0]}{'delafter'}=0;
			for(my $i=$left+1; $i<$right; $i++) {
				$subcon{$t[0]}{'delafter'}++
			}
		}

		# If there is overlap, we remove as much bp from the 
		# left subcontig as the length of the ovl!
		if($ovl>0) {
			$end=$end-$ovl;
			$subcon{$t[0]}{'remove'}=$ovl;
		}
		# If no overlap, save region from query! 
		else{
			$subcon{$t[0]}{'add'}{'name'}=$t[6];
			$subcon{$t[0]}{'add'}{'start'}=$t[4];
			$subcon{$t[0]}{'add'}{'end'}=$t[9];
			$subcon{$t[0]}{'add'}{'dir'}=$qdir;
		}

		# Save the alignment status of the left contig's right side
		$subcon{$t[0]}{'end'}=$end;

		# Save the alignment status of the right contig's left side
		$subcon{$t[12]}{'start'}=$t[7];
	}
}
close(IN);


# GO TROUGH BED FILE, CHECK STATUS FOR EVERY SUBCONTIG AND PRINT NEW BED FILE
open(BED, $BED);
while(<BED>){
	my @t=split(/\s+/, $_);

#	print STDERR "DEBUG PART2: Looking at ".$t[3]."\n";
	my ($s, $e, $fills, $fille);
	my $nextline="";
	my $descr=".";
	my $gapline="";
	my ($gap,$size)=("DUMMY1","DUMMY2");

	# If we are on the last subcontig, there is no following gap 
	unless(eof){
		$gapline=<BED>;
		my @u=split(/\s+/, $gapline);
		$gap=$u[3];
		$size=$u[2]-$u[1];
	}
	
	# If there is something saved in the hash:
	if(defined($subcon{$t[3]})) {

		# New start position saved
		if(defined($subcon{$t[3]}{'start'})) {
#			print STDERR "\twe have a start\n";
			$s=$subcon{$t[3]}{'start'}-1; #(subtract 1 to get bed format)
		}
		else {
			$s=0;
		}

		# New end position saved
		if(defined($subcon{$t[3]}{'end'})) {
#			print STDERR "\twe have an end\n";
			$e=$subcon{$t[3]}{'end'};
		}
		else{	
			$e=$t[2]-$t[1];
		}

		# Extract and save the subcontig with the new boundaries
		my $samstart=$s+1;
		my $name=$t[3];
		my $tempseq=`samtools faidx $TFASTA $name:$samstart-$e |grep -v ">" |tr -d "\n"`;
#		my $templen=length($tempseq);
#		print STDERR $name."\t".$templen."\n";
		$seq.=$tempseq;
#		print STDOUT "Length of seq is now ".length($seq)."\n";

		# If there is query sequence added in between
		if(defined($subcon{$t[3]}{'add'})) {
#			print STDERR "\twe have something added\n";
			$fills=min($subcon{$t[3]}{'add'}{'start'},$subcon{$t[3]}{'add'}{'end'}); #"Real" start is +1, but since bed format it's ok.
			$fille=max($subcon{$t[3]}{'add'}{'start'},$subcon{$t[3]}{'add'}{'end'})-1;	# -1 because we don't want to include the last aligned bp
			$descr="removed_gap_$gap";

			# (if the alignments turn out to be directly adjacent, there is nothing to fill with)
			unless($fille-$fills==0) {
				$nextline=$subcon{$t[3]}{'add'}{'name'}."\t".$fills."\t".$fille."\tfilling_gap_$gap\t.\t".$subcon{$t[3]}{'add'}{'dir'};
				$samstart=$fills+1;
				$name=$subcon{$t[3]}{'add'}{'name'};
				$tempseq=`samtools faidx $QFASTA $name:$samstart-$fille |grep -v ">" |tr -d "\n"`;
				if($subcon{$t[3]}{'add'}{'dir'} eq "-") {
					$tempseq=~tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
					$tempseq=reverse($tempseq);
				}
#				$templen=length($tempseq);
#				print STDERR $name."\t".$templen."\n";
				$seq.=$tempseq;
#				print STDOUT "Length of seq is now ".length($seq)."\n";

			}
			
		}
		elsif(defined($subcon{$t[3]}{'remove'})) {	
#			print STDERR "\twe have bp removed from left side\n";
			$descr="removed_".$subcon{$t[3]}{'remove'}."bp_and_gap_$gap";
		}
		else {
			unless(eof) {
				$nextline="GAP\t0\t$size\t$gap";
				$seq.="N"x$size;
#				print STDERR "GAP\t$size\n";
#				print STDOUT "Length of seq is now ".length($seq)."\n";
			}
		}

		if(defined($subcon{$t[3]}{'delafter'})) {
#			print STDERR "\twe have a full subcontig removed\n";
			for(my $i=1; $i<=$subcon{$t[3]}{'delafter'}; $i++) {
				my $newline=<BED>;
				my $newgap=<BED>;
				my @nl=split(/\s+/, $newline);
				my @ng=split(/\s+/, $newgap);
				$descr.="|removed_".$nl[3];
				$descr.="|removed_".$ng[3];
			}
		}
	}
	else { # Nothing saved, save the seq and the gap as it was
		$s=0;
		$e=$t[2]-$t[1];
		$nextline="GAP\t0\t$size\t$gap";
		
		my $name=$t[3];
		my $tempseq=`samtools faidx $TFASTA $name:1-$e |grep -v ">" |tr -d "\n"`;
		$seq.=$tempseq;
#		print STDOUT "Length of seq is now ".length($seq)."\n";
#		my $templen=length($tempseq);
#		print STDERR $name."\t".$templen."\n";
		unless(eof) {
			$seq.="N"x$size;
#			print STDOUT "Length of seq is now ".length($seq)."\n";
#			print STDERR "GAP\t$size\n";
		}
	
	}

	# Print to bed output
	print OUT $t[3]."\t".$s."\t".$e."\t".$descr."\t.\t+\n";
	unless(eof || $nextline eq "") {
		print OUT $nextline."\n";
	}
}
close(BED);
close(OUT);


# Print sequence to fasta output
open(OUTFA, ">$outfa");
print OUTFA ">".$OUTPREF."_closed\n";
my @blocks = split(/(.{100})/i, $seq);
foreach my $b (@blocks) {
	if($b ne "") {
		print OUTFA "$b\n";
	}
}
close(OUTFA);
