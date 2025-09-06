#!/usr/bin/perl -w


# dNdSForGenes.pl		  	  
# written by Linnéa Smeds                            15 Feb 2011
# --------------------------------------------------------------
# 
# --------------------------------------------------------------
# Usage:
#

use strict;

# Input parameters
my $genesInPeaks = $ARGV[0];
my $dNdSfile = $ARGV[1];
my $output = $ARGV[2];

my %dNdS = ();

open(IN, $dNdSfile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$dNdS{$tab[0]} = $tab[1];	
}
close(IN);

open(OUT, ">$output");
open(GENE, $genesInPeaks);
while(<GENE>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if(defined $dNdS{$tab[4]}) {
		print OUT $_."\t".$dNdS{$tab[4]}."\n";
	}
	else {
		print OUT $_."\tNA\n";
	}
		
}
close(GENE);
close(OUT);
