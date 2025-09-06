#!/usr/bin/perl

# rmNsAtEnds.pl	       
# written by Linnéa Smeds                    March 2012
# =====================================================
# Takes a fastqfile and removes the Ns at 5' and 3'end.
# =====================================================
# usage perl rmNsAtEnds.pl <IN> <OUT>
#
# example:
# perl rmNsAtEnds.pl file.fastq newfile.fastq


use strict;
use warnings;

my $time =time;

# Input parameters
my $fastqIN = $ARGV[0];
my $fastqOUT = $ARGV[1];



open(OUT, ">$fastqOUT");
open(IN, $fastqIN);
while(<IN>) {

	my $head = $_;
	my $seq = <IN>;
	my $plus = <IN>;
	my $qual = <IN>;
	chomp($seq);
	chomp($qual);

	$seq =~ s/^(N*)//;
	if($1) {
		$qual=substr($qual, length($1), length($qual)-length($1));
	}
	m//;	
	
	$seq =~ s/(N*)$//;
 	if($1) {
		$qual=substr($qual, 0, length($qual)-length($1));
	}
	
	print OUT $head.$seq."\n".$plus.$qual."\n";
}
close(IN);
close(OUT);
