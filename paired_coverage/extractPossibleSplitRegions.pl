#!/usr/bin/perl

# extractPossibleSplitRegions.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# Takes the output from findZeroPairedCoverageRegions.pl
# and filter out probable misassembled regions out of all
# zero coverage regions based on some conditions.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $zeroList = $ARGV[0];
my $lengthFile = $ARGV[1];
my $dist = $ARGV[2];
my $minSize = $ARGV[3];
my $maxSize = $ARGV[4];
my $output = $ARGV[5];

# Save all scaffold length in file
open(IN, $lengthFile);
my %lengths = ();
while(<IN>) {
	my ($head, $scaffLen) = split(/\t/,$_);
	chomp($scaffLen);
	my ($scaff, $rest) = split(/\s+/,$_);
	$scaff =~ s/>//;
	$lengths{$scaff}=$scaffLen;
}
close(IN);

open(OUT, ">$output");

#Go through the regions
open(IN, $zeroList);
my $rowCnt = 1;
my ($currScaff, $currEnd) = ("", "");
my $temp;
while(<IN>) {
	my ($scaff, $start, $end) = split(/\s+/,$_);
	my $size = $end-$start+1;
	if($rowCnt == 1) {
		if($start>$dist && $size>$minSize && $size<$maxSize) {
			$temp = $_;
		}
	}
	else {
		if($scaff eq $currScaff) {
			if ($start-$currEnd>$dist) {
				print OUT $temp;
				$temp = "";
				if($size>$minSize && $size<$maxSize) {
					$temp = $_;
				}
			}
			else {
				$temp = "";
			}
		}
		else {
			if($temp ne "" && $lengths{$currScaff}-$currEnd>$dist) {
				print OUT $temp;
			}
			$temp = "";
		
			if($start>$dist && $size>$minSize && $size<$maxSize) {
				$temp = $_;
			}
		}


	}
	$currScaff = $scaff;
	$currEnd = $end;
	$rowCnt++;
}
if( $temp ne "" && $lengths{$currScaff}-$currEnd>$dist) {
	print OUT $temp;
}
close(IN);
close(OUT);

