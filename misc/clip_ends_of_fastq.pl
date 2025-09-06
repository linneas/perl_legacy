#!/usr/bin/perl

# # # # # #
# clip_ends_of_fastq.pl
# written by Linnéa Smeds Oct 2011
# ===================================================
#
# ===================================================
# Usage: 

use strict;
use warnings;

my $time = time;

# Input parameters
my $fastqFile = $ARGV[0];
my $cut5 = $ARGV[1];
my $cut3 = $ARGV[2];
my $output = $ARGV[3];

open(OUT, ">$output");

my ($head, $seq, $plus, $qual);
open(IN, $fastqFile);
while(my $line = <IN>) {
	$head = $line;
	chomp($seq = <IN>);
	$plus = <IN>;
	chomp($qual = <IN>);


	$seq = substr($seq, $cut5, length($seq)-$cut5-$cut3);
	$qual = substr($qual, $cut5, length($qual)-$cut5-$cut3);
				
	print OUT $head . $seq ."\n" . $plus . $qual . "\n";
}
$time=time-$time;
$time=$time/60;
print "Time elapsed: $time min.\n";
			
