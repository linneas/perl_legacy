#!/usr/bin/perl


# # # # # #
# divideLengthFileAndPrintRunFile.pl
# written by Linnéa Smeds		    August 2011
# =====================================================
# Takes a file with sequence names and lengths, and 
# distribute the sequences over several files so no file
# have more than X bases or Y sequences.
# =====================================================

use strict;
use warnings;

# Input parameters
my $lengthFile = $ARGV[0];	# File with scaffold names and lengths
my $limBP = $ARGV[1];		# X bases
my $limNo = $ARGV[2];		# Y sequencea
my $minLen = $ARGV[3];		# min length of scaffold
my $prefix = $ARGV[4];		# output prefix


open(ALL, $lengthFile);

my ($accBP,$accNo) = (0,0);
my $fileCnt= 1;
my $cnt = 1;
my $templist = "";

while(<ALL>) {

	chomp($_);
	my ($head, $scaffLen) = split(/\t/,$_);

	if($scaffLen>=$minLen) {
	
		if($accBP>$limBP || $accNo>$limNo) {
			my $lenfile = $prefix."_".$fileCnt.".len";
			open(OUT, ">$lenfile");
			print OUT $templist;
			close(OUT);
			$templist = $_."\n";
			$accBP=$scaffLen;
			$accNo=1;
			$fileCnt++;
		}
		else {
			$templist.=$_."\n";
			$accBP+=$scaffLen;
			$accNo++;
		}
	
		$cnt++;
	}
	else {
		print "Warning: $head is too short to be used\n";
	}
}
my $lenfile = $prefix."_".$fileCnt.".len";
open(OUT, ">$lenfile");
print OUT $templist;
close(OUT);
close(ALL);

