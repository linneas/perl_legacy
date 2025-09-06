#!/usr/bin/perl

# getIndCov_perWindow.pl  	
# written by Linnéa Smeds,                30 March 2012
# =====================================================
# 
# =====================================================
# usage perl


use strict;
use warnings;

# Input parameters
my $allWindows = $ARGV[0];
my $dir = $ARGV[1];
my $fileExtn = $ARGV[2];
my $output = $ARGV[3];

open(OUT, ">$output");
open(IN, $allWindows);

while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_); 
	my $file = $tab[1].$fileExtn;

	my $totCov = 0;
	my $covBases = 0;
	
	if(-e "$dir/$file") {
		open(COV, "$dir/$file");
		while(my $line = <COV>) {
			my @tab2 = split(/\s+/, $line); 
			if($tab2[1]>$tab[2]) {
				if($tab2[1]<$tab[3]) {
					$totCov+=$tab2[2];
					$covBases++;
				}
				else {
					last;
				}
			}
		}
		close(COV);
	}
	my $meanCov = "noBases";
	unless($covBases==0) {
		$meanCov = $totCov/$covBases;
	}
	
	print OUT $_."\t".$meanCov."\n";
}	
close(OUT);
