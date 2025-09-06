#!/usr/bin/perl -w


# # # # # # 
# extractAndConcatSeq.pl	 Linnéa Smeds, March 30 2011
# ----------------------------------------------------------
# Takes a two column list with scaffold names and direction
# (+ or -), and concatenates the seqs to a fake chromosome.


use strict;

# Input parameters
my $fasta = $ARGV[0];
my $list = $ARGV[1];
my $name = $ARGV[2];
my $out = $ARGV[3];

#Saves the seq names in hash
my %seqs = ();
open(IN, $list);
my $cnt = 1;
while(<IN>) {
	my ($scaff, $strand) = split(/\s+/, $_);
	$scaff=~s/>//;
	$seqs{$scaff}{'sign'} = $strand;
	$seqs{$scaff}{'order'} = $cnt;
	$cnt++;
	#print "FIRST LOOP: adds $scaff to the hash\n";
}
close(IN);
$cnt--;

#Finds the sequences in the fasta
my $seq = "";
open(IN, $fasta);
while(<IN>) {
	if(/>/) {
		my @tab = split(/\s+/, $_);
		$tab[0]=~s/>//;
		#print "SECOND LOOP: finds ".$tab[0]." and checks if it's in the hash\n";
		if(exists $seqs{$tab[0]}) {
			#print "find the seq of ".$tab[0]." in the file\n";
			$seq = "";
			my $next = <IN>;
			while ($next !~ m/^>/) {
				chomp($next),
				$seq.= $next;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
			}
			seek(IN, -length($next), 1);

			if($seqs{$tab[0]}{'sign'} eq "-") {
				$seqs{$tab[0]}{'seq'} = &reverseComp($seq);
			}
			else {
				$seqs{$tab[0]}{'seq'} = $seq;
			}
			$seqs{$tab[0]}{'len'} = length($seq);
		}
	}
}
close(IN);
my $catChrom = "";
$seq="";

#Concatenates the sequences
my $bcnt = 0;
my $descOut = "$name"."_cat.description";
open(OUT, ">$descOut");
foreach my $key (sort {$seqs{$a}{'order'} <=> $seqs{$b}{'order'}} keys %seqs) {
	#print "THIRD LOOP: add the seq of $key to the cat chrom\n";
	#print "$key has the sequence ".$seqs{$key}{'seq'}."\n";
	$catChrom.=$seqs{$key}{'seq'};
	my $start = $bcnt+1;
	my $end = $bcnt+$seqs{$key}{'len'};
	print OUT $key."\t".$start."\t".$end."\n";
	delete $seqs{$key};
	$bcnt = $end;
}	
close(OUT);

#Print to file
open(OUT, ">$out");
unless(length($catChrom) == 0) {
	print OUT ">$name\t$cnt cat seq\n";
	my @blocks = split(/(.{100})/i, $catChrom);
	foreach my $b (@blocks) {
		if($b ne "") {
			print OUT "$b\n";
		}
	}
}
close(OUT);

%seqs = ();

## SUBROUTINES
# ------------------------------------------------------------
sub reverseComp() {
	my $DNAstring = shift;
	my $output = "";

	my @a = split(//, $DNAstring);
	for(@a) {
		$_ =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
		$output = $_ . $output;
	}
	return $output;
}

