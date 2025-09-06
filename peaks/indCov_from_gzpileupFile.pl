#!/usr/bin/perl

# indCov_from_gzpileupFile.pl  	
# written by Linnéa Smeds,                30 March 2012
# =====================================================
# 
# =====================================================
# usage perl


use strict;
use warnings;

# Input parameters
my $file = $ARGV[0];
my $output = $ARGV[1];

open(OUT, ">$output");

if(-e $file) {
	open(IN, "gunzip -c $file |");
	while(<IN>) {
		my @tab = split(/\s+/, $_); 
		
		my $collCov = 0;
		my $piedCov = 0;
	
		for(my $i=9; $i<=18; $i++) {
			my ($dummy, $cov) = split(/:/, $tab[$i]);
			if ($cov>0) {
				$collCov++;
			}
		}
		for(my $i=19; $i<=$#tab; $i++) {
			my ($dummy, $cov) = split(/:/, $tab[$i]);
			if ($cov>0) {
				$piedCov++;
			}
		}
		if($collCov>=7 && $piedCov>=7) {
			my $sumCov = $collCov+$piedCov;
			print OUT $tab[0]."\t".$tab[1]."\t".$sumCov."\n";
		}
	}
}

