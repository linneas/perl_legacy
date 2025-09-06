#!/usr/bin/perl


# getGenesInPeaks.pl		  	  
# written by Linnéa Smeds                            15 Jan 2011
# --------------------------------------------------------------
# Go through a list of peaks and extracts the genes in the 
# region. Also makes a summary with the no of genes per window.
# --------------------------------------------------------------
# Usage:
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $windFile = $ARGV[0];
my $genesGFF = $ARGV[1];
my $prefix = $ARGV[2];

my $tempGFF = "tempfile";
system("awk '(\$3==\"gene\"){print \$1\"\t\"\$4\"\t\"\$5\"\t\"\$13}' $genesGFF >$tempGFF");

my %windows = ();

open(IN, $windFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$windows{$tab[1]}{$tab[2]}{'chr'} = $tab[0];
	$windows{$tab[1]}{$tab[2]}{'stop'} = $tab[3];
	$windows{$tab[1]}{$tab[2]}{'genes'} = [];
	
}
close(IN);

open(GENE, $tempGFF);
while(<GENE>) {
	my @tab = split(/\s+/, $_);
	my ($bestWind, $bestStart, $bestOverlap) = ("","",0);
	foreach my $key (keys %{$windows{$tab[0]}}) {
		if($key<=$tab[2] && $windows{$tab[0]}{$key}{'stop'}>=$tab[1]) {
			my $overlap = min($windows{$tab[0]}{$key}{'stop'},$tab[2])-max($key, $tab[1])+1;
			if($overlap>$bestOverlap) {
				$bestWind=$tab[0];
				$bestStart=$key;
				$bestOverlap=$overlap;
			}
		}
	}
	if($bestWind ne "") {
		push(@{$windows{$bestWind}{$bestStart}{"genes"}}, $tab[3]);
	}
}
close(GENE);

open(IN, $windFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	if( scalar(@{$windows{$tab[1]}{$tab[2]}{'genes'}}) >0) {
		foreach my $gene (@{$windows{$tab[1]}{$tab[2]}{'genes'}}) {
			print $tab[0]."\t".$tab[1]."\t".$tab[2]."\t".
				$tab[3]."\t".$gene."\n";
		}
	}
}
close(IN);
