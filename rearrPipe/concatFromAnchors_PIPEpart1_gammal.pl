#!/usr/bin/perl

# # # # # #
# concatFromAnchors_PIPEpart1.pl		
# written by Linnéa Smeds        18 April, mod 12 Sept 2011
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of chromosomes, and a prefix and suffix for
# the lastz files (one for each chromosome), a config file
# with parameters for the stepwise merging, and a file with
# the flycatcher scaffold lengths.

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $lastzfile = $ARGV[1];
my $configFile = $ARGV[2];
my $scaLenFile = $ARGV[3];

my ($steps, $last);
my $concatList = "all_cat.list";
open(OUT, ">$concatList");		#Initiating file
close(OUT);

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND RUN THE DIFFERENT STEPS
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);

	&makeAnchorFile($chrom, $lastzfile);
	&removeOverlaps($chrom);
	($last, $steps) = &allMergeSteps($chrom, $configFile);
	&makeScaffoldList($chrom, $last);
	
}
close(IN);

# RUN FINAL STEPS FOR CONCATENATED FILES
&makeConcatAnchorFile($steps);
&checkMultAndAssign($steps, $concatList, $scaLenFile, $chrList);

# PREPARE LISTS FOR MAKING THE ARTIFICIAL CHROMOSOMES
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);

	&makeConcatList($chrom);
}
close(IN);



# Subroutines
# -----------------------------------------

sub makeAnchorFile {

	my $chrom = shift;
	my $file = shift;

	my $chrNo = $chrom;
	$chrNo =~ s/chr//;
	my $outAnc = $chrom.".anchors";
	system("awk '(\$1 ==\"$chrNo\"){print}' $lastzfile | sort -k2n >$outAnc");

}

sub removeOverlaps {

	my $chrom = shift;

#	print "remove overlaps for $chrom\n";

	my $infile = $chrom.".anchors";
	my $outfile = $chrom."_noovl.anchors";

	# Variables
	my @oldinfo;
	my ($oldinfoFlag, $infoFlag) = ("off", "off");
	my @info;
	my $cnt = 0;
	my $lastline;
	open(OUT, ">$outfile");

	# Goes through the (sorted) anchor file and check any consecutive anchors
	# overlaps in the reference genome
	open(THIS,$infile);
	while (my $line = <THIS>) {
		@info = split(/\t/, $line);
		chomp(@info);
		if($cnt>0){	
			if ($info[0] eq $oldinfo[0] && $info[1]<$oldinfo[2]) {
				$infoFlag = "on";
			}
			else {
				if($oldinfoFlag eq "off") {
			    foreach my $val (@oldinfo) {
						print OUT $val."\t";
					}
					print OUT "\n";
				}
			$infoFlag = "off";
			}
		}
		@oldinfo = @info;
		$oldinfoFlag = $infoFlag;
		$cnt++;
	}
	#Prints the last segment
	if($oldinfoFlag eq "off") {
		foreach my $val (@oldinfo)  {
			print OUT $val."\t";
		}
	}
	print OUT "\n";
	close(THIS);
	close(OUT);

}

sub removeShortAnchors {
	my $infile = shift;
	my $outfile = shift;
	my $threshold = shift;

	open(THIS,$infile);
	open(OUT,">$outfile");
	while (my $line = <THIS>) {
		chomp($line);
		unless($line eq "") {
			my @tab = split(/\s/, $line);
			if($tab[2]-$tab[1] >= $threshold && abs($tab[6]-$tab[5])>= $threshold) {
				print OUT $line."\n";		
			}
		}
	}
	close(OUT);
	close(THIS);

}

sub mergeCloseAnchors {
	my $infile = shift;
	my $outfile = shift;
	my $threshold = shift;

	# Variables
	my @oldinfo;
	my @info;
	my $cnt = 0;
	my $lastline;

	# Goes through the anchor file and check if the rows 
	# fulfills the merging conditions
	open(THIS,$infile);
	open(OUT, ">$outfile");
	while (my $line = <THIS>) {
		@info = split(/\s+/, $line);
		chomp(@info);
		if($cnt>0){
			if (defined $info[4] && defined $oldinfo[4] && defined $info[7] && defined $oldinfo[7]) {

				if($info[4] eq $oldinfo[4] && $info[7] eq $oldinfo[7] && ($info[1]-$oldinfo[2] < $threshold)) {
					if(($info[7] eq "+") && (abs($info[5]-$oldinfo[6]) < $threshold) && ($info[6]>$oldinfo[6])){
						$info[1] = $oldinfo[1];
						$info[5] = $oldinfo[5];
					}
					elsif(($info[7] eq "-") && (abs($info[6]-$oldinfo[5]) < $threshold) && ($info[5]<$oldinfo[5])) {
						$info[1] = $oldinfo[1];
						$info[6] = $oldinfo[6];
					}
					else {
						foreach my $val (@oldinfo) {
							print OUT $val."\t";
						}
						print OUT "\n";
					}
				}
				else {
					foreach my $val (@oldinfo) {
						print OUT $val."\t";
					}
					print OUT "\n";
				}
			}
			else {
				print "What happened here? A value is missing on line: $line";
			}
		}
		@oldinfo = @info;
		$cnt++;
	}
	close(THIS);

	#Prints the last segment
	foreach my $val (@oldinfo)  {
		print OUT $val."\t";
	}
	print OUT "\n";
	close(OUT);
}

sub allMergeSteps {

	my $chrom = shift;
	my $configFile = shift;

	open(CNF, $configFile);
	my $cnt = 1;
	
	my $prevFile = $chrom."_noovl.anchors";
	my $outStep = "";
	while(my $line = <CNF>) {
		chomp($line);
		if($line =~ m/^#/ || $line eq "") {
			next;
		}
		else {
			my ($type, $lim) = split(/\s+/, $line);
			$outStep = $chrom."_step".$cnt.".anchors";
			if($type eq "M") {
#				print "sending type $type and lim $lim to merge\n";
				&mergeCloseAnchors($prevFile, $outStep, $lim);
			}
			elsif($type eq "R") {
#				print "sending type $type and lim $lim to remove\n";
				&removeShortAnchors($prevFile, $outStep, $lim);
			}
			else {
				die "Type must be either M or R!!";
			}
			$prevFile = $outStep;
			$steps = $cnt;
			$cnt++;
		}
	}
	return ($outStep, $steps);
}

sub makeScaffoldList {

	my $chrom = shift;
	my $outStep = shift;
	my $outCatList = $chrom."_cat.list";
	system("awk '{print \$5\"\\t\"\$8}' $outStep >$outCatList");
	system("awk '{print \"$chrom\t\"\$5\"\\t\"\$8}' $outStep >>$concatList");

}

sub makeConcatAnchorFile {
	my $steps = shift;

	my $concatAnch = "all_step$steps.anchors";
	system("cat chr*_step$steps.anchors >$concatAnch");
}


sub checkMultAndAssign {

	my $steps = shift;
	my $concatList = shift;
	my $scaLenFile = shift;
	my $chrList = shift;

	print "step is $steps\n";

	my $concatAnch = "all_step$steps.anchors";
	
	system("awk '{print \$1\"\t\"\$5}' $concatAnch |sort |uniq -c |awk '{print \$3}' |sort |uniq -c |awk '(\$1>1){print \$2}' >anchor_to_multiple");
	system("perl ~/private/scripts/rearrPipe/assignScaffolds2Chrom.pl anchor_to_multiple $concatList $scaLenFile step$steps.anchors $chrList anchor_to_multiple_nonUn");

}

sub makeConcatList {

	my $chrom = shift;

	my $oldlist = $chrom."_cat.list.cleaned";
	my $newlist = $chrom."_artificial.list";

	system("uniq -c $oldlist |awk '{print \$2\"\t\"\$3\"\t\"\$1}' >makeConcatList.tempfile");

	open(LST, "makeConcatList.tempfile");
	my %seqs = ();
	my $cnt=1;
	while(<LST>) {
		my ($scaff, $sign, $no) = split(/\s+/,$_);
		unless ($scaff eq "") {
			if(defined $seqs{$scaff}) {
				if($no > $seqs{$scaff}{'no'}) {
					$seqs{$scaff}{'sign'} = $sign;
					$seqs{$scaff}{'no'} = $no;
				}
			}
			else {
				$seqs{$scaff}{'sign'} = $sign;
				$seqs{$scaff}{'no'} = $no;
			}
			$cnt++;	
		}
	}
	close(LST);
	system("rm makeConcatList.tempfile");

	unless (!keys %seqs) {
		open(OUT, ">$newlist");
		foreach my $key (sort {$seqs{$a}{'no'} <=> $seqs{$b}{'no'}} keys %seqs) {
			print OUT $key."\t".$seqs{$key}{'sign'}."\n";
		}
		close(OUT);
	}
}
