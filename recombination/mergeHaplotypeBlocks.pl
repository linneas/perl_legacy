#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# mergeHaplotypeBlocks.pl
# written by Linnéa Smeds                      29 June 2015
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a combined parent-offspring file with phased haplo
# types and a last column stating if the SNP comes from the
# maternal (Mat) or paternal (Pat) grandparent, and merges
# any adjacent SNPs from the same haplotype into bigger
# blocks. 
#
# Infile
# Chr13	103066	0|0	1|1	1|0	1|0	0|0	1|0	Mat
# Chr13	105372	1|1	0|0	0|1	0|1	0|0	0|0	Mat
# Chr13	108210	1|1	0|0	0|1	0|1	0|0	0|0	Pat
#
# Outfile (not bed! Just standard pos)
# CHR	START	END		HAP	NO_OF_SNPS
# Chr13	103066	105372	Mat	2
# Chr13	108210	108210	Pat	1
# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $OUT = $ARGV[1];


open(OUT, ">$OUT");		#Initiating outfile

# GO THROUGH THE FILE
open(IN, $FILE);
my ($chr,$state,$snpcnt,$start,$end) = ("","", 0, 0, 0, 0);
my $linecnt=0;
my $snpsum=0;

while(<IN>) {
	my @t=split(/\s+/,$_);
	
	if($linecnt==0) {
        $state=$t[8];
        $start=$t[1];
        $end=$t[1];
        $chr=$t[0];
        $snpcnt=1;
	}
	else{
		if($t[8] eq $state) {	# the SNP belongs to the previous block
			$end=$t[1];
			$snpcnt++;
		} 
		else {					# found a new block, print the old one
			print OUT $chr."\t".$start."\t".$end."\t".$state."\t".$snpcnt."\n";
	        $state=$t[8];
     	    $start=$t[1];
        	$end=$t[1];
        	$chr=$t[0];
        	$snpsum+=$snpcnt;
        	$snpcnt=1;
		}
	}
	$linecnt++;
}
close(IN);

# Print the last block:
print OUT $chr."\t".$start."\t".$end."\t".$state."\t".$snpcnt."\n";
$snpsum+=$snpcnt;
print "Looked at $linecnt lines with $snpsum snps\n";
close(OUT);

