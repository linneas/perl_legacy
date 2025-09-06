#!/usr/bin/perl

# splitSeqInFasta.pl
# written by Linnéa Smeds                         June 2011
# =========================================================
# Takes a fasta file and extract the X first rows from 
# each sequence (and X rows every N rows).
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $xrows = $ARGV[1];
my $nrows = $ARGV[2];
my $output = $ARGV[3];

my ($seq,$head) = ("","");
my ($scaffCnt,$newCnt) = (0,0);
my $currScaff = "";
my ($printrows, $rowcnt, $partcnt, $printflag);

open(IN, $fasta);
open(OUT, ">$output");
while(<IN>) {
	if($_ =~ m/^>/) {
		my @tab = split(/\s+/, $_);
		$currScaff = $tab[0];
		print OUT $currScaff."\n";
		$printrows = 0;
		$rowcnt = 0;
		$partcnt = 1;
		$printflag = 1;
	}
	else {
		$printrows++;
		$rowcnt++;

		if($printflag == 1) {
			print OUT $_;
			if($printrows==$xrows) {
#			print "stop printing out the $partcnt partof $currScaff\n";
				$printflag = 0;
				$printrows = 0;
			}				
		}

		if($rowcnt % $nrows == 0) {
			$printflag = 1;
			$printrows = 0;
			$partcnt++;
#			print "start another printing round $partcnt for $currScaff. Total row no is $rowcnt\n"; 
			print OUT $currScaff."_".$partcnt."\n";
		}
	}
}
	
