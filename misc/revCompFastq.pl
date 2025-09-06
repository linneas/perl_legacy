#!/usr/bin/perl


# # # # # #
# revCompFastq.pl
# written by Linnéa Smeds                     Sept 2012
# =====================================================
# Takes the reverse complement of a fastq file and of
# course write the quality scores backwars as well)
# =====================================================
# Usage: revCompFastq.pl <seqfile.fq> <revseqfile.fq>
#

use strict;
use warnings;

# Input parameters
my $inFq = $ARGV[0];
my $outFq = $ARGV[1];


open(IN, $inFq);
open(OUT, ">$outFq");

while(<IN>) {
	if($_ =~ m/^@/) {
		my $head = $_;
		my $seq = <IN>;
		my $plus = <IN>;
		my $qual = <IN>;
		chomp($qual);
		chomp($seq);

		$seq = &reverseComp($seq);
		$qual = reverse($qual);

		print OUT $head.$seq."\n".$plus.$qual."\n";

	
	}
}


sub reverseComp { 
	my $DNAstring = shift;

	my $output = "";

	my @a = split(//, $DNAstring);

	for(@a) {
		$_ =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
		$output = $_ . $output;
	}

	return $output;
}

