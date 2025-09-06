#!/usr/bin/perl -w


# mean_dSperWindow.pl		  	  
# written by Linnéa Smeds                          30 March 2012
# --------------------------------------------------------------
# 
# --------------------------------------------------------------
# Usage:
#

use strict;

# Input parameters
my $windFile = $ARGV[0];
my $genesInWind = $ARGV[1];
my $dSfile = $ARGV[2];
my $minAlignLen = $ARGV[3];
my $output = $ARGV[4];

my %dS = ();

open(IN, $dSfile);
<IN>;	#Get rid of header
while(<IN>) {
	my @tab = split(/\s+/, $_);
	if($tab[6]>=$minAlignLen) {
		$dS{$tab[0]} = $tab[3];
	}	
}
close(IN);


my %windGenes = ();

open(GENE, $genesInWind);
while(<GENE>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	$windGenes{$tab[1]}{$tab[2]}{$tab[4]}=1;
}
close(GENE);


open(OUT, ">$output");
open(WIND, $windFile);
while(<WIND>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if (defined $windGenes{$tab[1]}{$tab[2]}) {
		my $totdS = 0;
		my $totNum = 0;
		foreach my $gene (keys %{$windGenes{$tab[1]}{$tab[2]}}) {
			if(defined $dS{$gene}) {
				$totdS+=$dS{$gene};
				$totNum++;
			}
		}
		my $meandS="na";
		unless($totNum==0) {
			$meandS = $totdS/$totNum;
		}
		print OUT $_."\t".$meandS."\n";
	}
	else {
		print OUT $_."\tna\n";
	}
}
close(WIND);
close(OUT);
