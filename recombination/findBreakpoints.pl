#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# findBreakpoints.pl
# written by Linnéa Smeds                     22 April 2014
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a combined parent-offspring file with phased haplo
# types and a last column stating if the SNP comes from the
# maternal (Mat) or paternal (Pat) grandparent. Breaks between 
# the two types are registrered. If there are less than some
# given values of consecutive SNPs of the same type, or the
# region is too short, they are counted to be erroneous calls.
# Both a number and a length is desired, otherwise one might 
# loose regions when a new erroneous SNP comes less than len-
# thres into the new state, and is considered to be a part of
# the previous state.
#
# Infile
# Chr13	103066	0|0	1|1	1|0	1|0	0|0	1|0	Mat
# Chr13	105372	1|1	0|0	0|1	0|1	0|0	0|0	Mat
# Chr13	108210	1|1	0|0	0|1	0|1	0|0	0|0	Mat
#
# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $NTHRES = $ARGV[1];
my $LTHRES = $ARGV[2];
my $OUT = $ARGV[3];


open(OUT, ">$OUT");		#Initiating outfile

# GO THROUGH THE FILE
open(IN, $FILE);
my ($chr,$state,$cnt,$start,$end,$ocnt) = ("","", 0, 0, 0, 0);
my ($tempstate,$tempcnt,$templen,$tempstart,$tempend)= ("", 0, 0, 0);
my $linecnt=0;

while(<IN>) {
	my @t=split(/\s+/,$_);
	if($linecnt==0) {
		$cnt++;
        $state=$t[8];
        $start=$t[1];
        $end=$t[1];
        $chr=$t[0];
	}
	else{
		if($tempstate ne "") {	# This means we have a temporary state saved 
			if($tempstate eq $t[8]) {	#..if that state is found again
				$tempend=$t[1];
				$tempcnt++;
				$templen=$tempend-$tempstart+1;
				if($tempcnt>$NTHRES || $templen>$LTHRES) {	#There are too many or a too long tempstate(s) in a row - time to make them permanent!
					print OUT $chr."\t".$start."\t".$end."\t".$state."\t".$cnt."\t".$ocnt."\n";
					$state=$tempstate;
					$start=$tempstart;
					$end=$tempend;
					$cnt=$tempcnt;
					$ocnt=0;
					($tempstate, $tempstart, $tempend, $tempcnt, $templen) = ("",0,0,0,0);
					
				}
			}
			else {		# If temporary state is NOT found again (=> first state found)
				if($tempcnt<=$NTHRES && $templen<=$LTHRES) {	#This is supposed to always be true
					if($state eq $t[8]) {	# This should also be true
						$end=$t[1];
						$cnt++;	
						$ocnt+=$tempcnt;
						($tempstate, $tempstart, $tempend, $tempcnt, $templen) = ("",0,0,0,0);
					}
					else {
						print "ERROR ON LINE: $_"; 
						print "\tlast column is neither $state nor $tempstate\n";
					}
				}
				else {
					print "ERROR ON LINE $_";
					print "\ttempcnt $tempcnt is larger than thres $NTHRES\n";
				}
			}
		}
		else {		# No tempstate is saved!		
			if($t[8] eq $state) {
				$cnt++;
				$end=$t[1];
			}

			else {
 				$tempstate=$t[8];
				$tempstart=$t[1];
				$tempend=$t[1];
				$tempcnt=1;
				$templen=0;
			}
		}
	}
	$linecnt++;
}
close(IN);

# PRINT THE LAST STATE AND TEMPSTATE AS WELL!!!
print OUT $chr."\t".$start."\t".$end."\t".$state."\t".$cnt."\t".$ocnt."\n"; # FIX THIS SO IT PRINTS CHROMOSOME AND CHECK IF THERE ARE TEMP STATES!
unless($tempstate eq "") {
	print OUT $chr."\t".$tempstart."\t".$tempend."\t".$tempstate."\t".$tempcnt."\n";
}	
close(OUT);

