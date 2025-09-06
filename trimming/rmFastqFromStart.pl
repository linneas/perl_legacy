#!/usr/bin/perl

# rmFastqFromStart.pl	       
# written by Linnéa Smeds                      Jan 2012
# =====================================================
# Takes a fastqfile and removes the first N bases based
# on some quality contition for a certain position X.
# =====================================================
# usage perl rmFastqFromStart.pl <IN> <QUALITY> 
#                     <POSITION> <REMOVE> <OUT>
#
# example - if the quality on position 20 is less than
# 29, remove the first 23 bases:
# perl rmFastqFromStart.pl file.fastq \
#	          29 20 23 newfile.fastq


use strict;
use warnings;

my $time =time;

# Input parameters
my $FastqFile = $ARGV[0];
my $minQ = $ARGV[1];
my $pos = $ARGV[2];
my $rmN = $ARGV[3];
my $outFile = $ARGV[4];

# Other parameters
my $scoreLevel = 64;
my $rmCnt = 0;
my $shortThres = 25;
my $shortCnt = 0;
my $totCnt = 0;

# ====================================================
# Goes through each fastq entry and checks the quality 
# of the Xth position
open(OUT, ">$outFile");
open(IN, $FastqFile);
while(<IN>) {

	my $head = $_;
	my $seq = <IN>;
	my $plus = <IN>;
	my $qual = <IN>;
	
	my @t = split("", $qual);
	if (ord($t[$pos-1])-$scoreLevel < $minQ) {
		$seq = substr($seq, $rmN, length($seq)-$rmN);
		$qual = substr($qual, $rmN, length($qual)-$rmN);
		$rmCnt++;
		if(length($seq)-1<$shortThres) {
			$shortCnt++;
		}
	}
	print OUT $head.$seq.$plus.$qual;
	$totCnt++;
}
close(IN);
close(OUT);

$time = (time-$time)/60;
print "$totCnt reads processed, $rmCnt were trimmed to pos $rmN from 5'\n";
print "$shortCnt reads are now shorter than $shortThres\n";
print "Time elapsed: $time min\n";

