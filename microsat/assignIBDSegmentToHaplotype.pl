#!/usr/bin/perl

# assignIBDSegmentToHaplotype.pl  	
# written by Linnéa Smeds,                  20 Mar 2016
# =====================================================
# 
#
# =====================================================
# usage: perl assignIBDSegmentToHaplotype.pl  	

use strict;
use warnings;
use List::Util qw(min max);


# Input parameters
my $FILE = $ARGV[0];	# Genotype for one individuals pasted with known haplotypes:
my $INFO = $ARGV[1];	# CHR, POS, GT, CHR, POS, A, B, C, D


# Go through the file and try to match the GTs with the haplotypes
open(IN, $FILE);
my ($A, $B, $C, $D, $tot) = (0,0,0,0,0);
while(<IN>) {
	my @t = split(/\s+/, $_);
	unless($t[2] eq ".") {
		if($t[2] eq $t[5]) {
			$A++;
		}
		if($t[2] eq $t[6]) {
			$B++;
		}
		if($t[2] eq $t[7]) {
			$C++;
		}
		if($t[2] eq $t[8]) {
			$D++;
		}
		$tot++;
	}
}
close(IN);

# Check which GT is matched
if($tot==0) {
	print $INFO." - 0 0\n";
}
else {
	my $hap="";
	my $Afrac=$A/$tot;
	my $Bfrac=$B/$tot;	
	my $Cfrac=$C/$tot;
	my $Dfrac=$D/$tot;

	my $max=max($Afrac,$Bfrac,$Cfrac,$Dfrac);
	if($max==0) {
		print $INFO." - 0 $tot\n";
	}
	else {
		if($max==$Afrac){
			$hap="A";
		}
		if($max==$Bfrac){		
			if($hap eq ""){
				$hap="B";
			}
			else {
				$hap.="|B";
			}
		}
		if($max==$Cfrac){		
			if($hap eq ""){
				$hap="C";
			}
			else {
				$hap.="|C";
			}
		}
		if($max==$Dfrac){		
			if($hap eq ""){
				$hap="D";
			}
			else {
				$hap.="|D";
			}
		}
		print $INFO." ".$hap." ".$max." ".$tot."\n";
	}
}


















 




