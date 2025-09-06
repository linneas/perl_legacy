#!/usr/bin/perl

# # # # # #
# covWindowsFromPileup.pl
# written by Linnéa Smeds 		     April 2011
# =====================================================
# Takes a file from mpileup, either with all columns, 
# or just the first 4 (scaffold, position, base, cov),
# and makes a denser coverage file for a given window 
# size, and a coverage summary per scaffold. The output
# file also contains the GC-content and no of Ns per
# window.
# =====================================================
# Usage: perl covWindowsFromPileup.pl <pileupfile> 
#			<window size> <output prefix>
#
# Example: perl covWindowsFromPileup.pl fAlb13.pileup \
#		500 fAlb13

use strict;
use warnings;

# Input parameters
my $pileup = $ARGV[0];
my $windowsize = $ARGV[1];
my $prefix = $ARGV[2];

# Output files
my $windowOut = $prefix."_".$windowsize.".cov";
my $sumOut = $prefix."_"."summary.cov";
open(OUT, ">$windowOut");
open(SUM, ">$sumOut");
print OUT "SEQ\tWSTART\tWEND\tMEANCOV\tGCCONT\tNs\n";
print SUM "SEQ\tLENGTH\tMEANCOV\tGCCONT\tNs\n";

# Initiating variables
my $current;
my $totcnt = 0;
my ($tmp_cnt, $curr_cnt, $curr_cov, $curr_wind_st) = (0, 1, 0, 1);
my ($gc, $at) = (0, 0);
my ($sc_cnt, $sc_cov, $sc_gc, $sc_at) = (1, 0, 0, 0);

#Go through each line in the pileup file
open(IN, $pileup);
while(<IN>) {
	my @tab = split(/\s+/, $_);

	if($totcnt == 0) {
		$current = $tab[0];
		$curr_cov += $tab[3];
		$sc_cov += $tab[3];
	}
	else {
		if($tab[0] eq $current) {
			if($tmp_cnt+1 < $windowsize) {
				$curr_cnt++;
				$curr_cov += $tab[3];
				$tmp_cnt++;
			}
			else {
				#print "going for printing! antalet AT är $at\n";
				my $cov = int($curr_cov/$windowsize+0.5);
				my $gc_cont = "noBases";
				unless($at+$gc == 0) {	
					#print "inside unless!\n";
					$gc_cont = $gc/($at+$gc);
				}
				my $nonATGC = $windowsize-($at+$gc); 
				print OUT $current."\t".$curr_wind_st."\t".$sc_cnt."\t".$cov."\t".$gc_cont."\t".$nonATGC."\n";
				$curr_wind_st = $sc_cnt+1;
				$curr_cnt = 1;
				$curr_cov = $tab[3];
				$tmp_cnt=0;
				($at, $gc) = (0, 0);
			}
			$sc_cnt++;
			$sc_cov += $tab[3];
		}
		else {
			my $cov = int($curr_cov/$curr_cnt+0.5);
			my $sum = int($sc_cov/$sc_cnt+0.5);
			my $gc_cont = "noBases";
			unless($at+$gc == 0) {	
				$gc_cont = $gc/($at+$gc);
			}
			my $nonATGC = $curr_cnt-($at+$gc);
			my $sc_gc_cont = "noBases"; 
			unless($sc_at+$sc_gc == 0) {
				$sc_gc_cont = $sc_gc/($sc_at+$sc_gc);
			}
			my $sc_nonATGC = $sc_cnt-($sc_at+$sc_gc);
			print OUT $current."\t".$curr_wind_st."\t".$sc_cnt."\t".$cov."\t".$gc_cont."\t".$nonATGC."\n";
			print SUM $current."\t".$sc_cnt."\t".$sum."\t".$sc_gc_cont."\t".$sc_nonATGC."\n";
			($sc_cnt, $sc_cov) = (1, $tab[3]);
			($tmp_cnt, $curr_cnt, $curr_cov, $curr_wind_st) = (0, 1, $tab[3], 1); 
			$current = $tab[0];	
			($at, $gc) = (0, 0);
			($sc_at, $sc_gc) = (0, 0);
		}
	}
	if($tab[2] =~ m/[a,t]/i) {
		#print "basen är A eller T\n";
		$at++;
		$sc_at++;
	}
	elsif($tab[2] =~ m/[g,c]/i) {
		#print "basen är G eller C\n";
		$gc++;
		$sc_gc++;
	}
	$totcnt++;
}
my $cov = int($curr_cov/$curr_cnt+0.5);
my $sum = int($sc_cov/$sc_cnt+0.5);
my $gc_cont = $gc/($at+$gc);
my $nonATGC = $curr_cnt-($at+$gc);
my $sc_gc_cont = $sc_gc/($sc_at+$sc_gc);
my $sc_nonATGC = $sc_cnt-($sc_at+$sc_gc);
print OUT $current."\t".$curr_wind_st."\t".$sc_cnt."\t".$cov."\t".$gc_cont."\t".$nonATGC."\n";
print SUM $current."\t".$sc_cnt."\t".$sum."\t".$sc_gc_cont."\t".$sc_nonATGC."\n";

