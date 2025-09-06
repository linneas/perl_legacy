#!/usr/bin/perl -w


# markPosSel.pl		  	  
# written by Linnéa Smeds                            15 Feb 2011
# --------------------------------------------------------------
# 
# --------------------------------------------------------------
# Usage:
#

use strict;

# Input parameters
my $genesInPeaks = $ARGV[0];
my $genesToMark = $ARGV[1];
my $output = $ARGV[2];

my %genes = ();

open(IN, $genesToMark);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$genes{$tab[0]} = 1;	
}
close(IN);

open(OUT, ">$output");
open(GENE, $genesInPeaks);
while(<GENE>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if(defined $genes{$tab[4]}) {
		print OUT $_."\t1\n";
	}
	else {
		print OUT $_."\t0\n";
	}
		
}
close(GENE);
close(OUT);
