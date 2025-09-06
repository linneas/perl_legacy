#!/usr/bin/perl

# # # # #
# createLengthFile.pl             written by LS 2013-12-02
# ========================================================
# Takes a fasta file and prints scaffold name and lengths.
# If the name includes spaces, only the first part is used
# in the output (compatible with e.g. blast and samtools).
# ========================================================
# usage perl createLengthFile.pl assembly.fa length.out

use strict;
use warnings;

my $in = $ARGV[0];
my $list =$ARGV[1];


open(IN, $in);
open(OUT, ">$list");

my $seq = "";
my $head = "";
my $cnt=0;
while(<IN>) {
 	chomp($_);
	
	if($_ =~ m/^>/) {
		
		if ($cnt!=0) {
			print OUT $head."\t".length($seq)."\n";
		}
		$seq="";
		my @tab=split(/\s+/, $_);
		$head = $tab[0];
		$head=~s/>//;
		$cnt++;
	}
	else {
		$seq.=$_;
	}
	
}
print OUT $head."\t".length($seq)."\n";
$seq="";


