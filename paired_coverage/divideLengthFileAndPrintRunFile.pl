#!/usr/bin/perl


# # # # # #
# divideLengthFileAndPrintRunFile.pl
# written by Linnéa Smeds		            August 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $bam = $ARGV[0];
my $lengthFile = $ARGV[1];
my $limBP = $ARGV[2];
my $limNo = $ARGV[3];
my $minLen = $ARGV[4];
my $prefix = $ARGV[5];
my $commandfile = $ARGV[6];

open(COM1, ">$commandfile"."1");
open(COM2, ">$commandfile"."2");


open(ALL, $lengthFile);

my ($accBP,$accNo) = (0,0);
my $fileCnt= 1;
my $cnt = 1;
my $templist = "";

while(<ALL>) {

	chomp($_);
	my ($head, $scaffLen) = split(/\t/,$_);

	if($scaffLen>$minLen) {
	
		if($accBP>$limBP || $accNo>$limNo) {
			my $lenfile = $prefix."_".$fileCnt.".len";
			my $pileupfile = $prefix."_".$fileCnt.".pileup";
			my $zerofile = $prefix."_".$fileCnt.".zerolist";
			open(OUT, ">$lenfile");
			print OUT $templist;
			close(OUT);
			print COM1 "perl ~/private/scripts/pairedCoverageFromBAM.pl $bam $lenfile $pileupfile &\n";
			print COM2 "perl ~/private/scripts/findZeroPairedCoverageRegions.pl $pileupfile $zerofile &\n";
			$templist = "";
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
}
my $lenfile = $prefix."_".$fileCnt.".len";
my $pileupfile = $prefix."_".$fileCnt.".pileup";
my $zerofile = $prefix."_".$fileCnt.".zerolist";
open(OUT, ">$lenfile");
print OUT $templist;
close(OUT);
print COM1 "perl ~/private/scripts/pairedCoverageFromBAM.pl $bam $lenfile $pileupfile &\n";
print COM2 "perl ~/private/scripts/findZeroPairedCoverageRegions.pl $pileupfile $zerofile &\n";


close(ALL);
close(COM1);
close(COM2);
