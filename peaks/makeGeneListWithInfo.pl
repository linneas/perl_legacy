#!/usr/bin/perl


# makeGeneListWithInfo.pl		  	  
# written by Linnéa Smeds                            15 Jan 2011
# --------------------------------------------------------------
# 
# --------------------------------------------------------------
# Usage:
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $windFile = $ARGV[0];
my $genesGFF = $ARGV[1];
my $windGeneFile = $ARGV[2];
my $extraInfo = $ARGV[3];
my $out = $ARGV[4];

# Columns in extra file
my @columns = (1,3);
my $headers = "dN/dS\tdS";

my $tempGFF = "tempfile";
system("awk '(\$3==\"gene\"){print \$1\"\t\"\$4\"\t\"\$5\"\t\"\$13}' $genesGFF >$tempGFF");

my %windows = ();
open(IN, $windFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$windows{$tab[1]}{$tab[2]}{'chr'} = $tab[0];
	$windows{$tab[1]}{$tab[2]}{'stop'} = $tab[3];
	$windows{$tab[1]}{$tab[2]}{'peak'} = $tab[4];
	
}
close(IN);

my %genes = ();
open(IN, $tempGFF);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my @name =split(/\|/, $tab[3]);
	$genes{$name[0]}{'start'} = $tab[1];
	$genes{$name[0]}{'stop'} = $tab[2];
}
close(IN);

my %extras = ();
open(IN, $extraInfo);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$extras{$tab[0]} = [];
	for(@columns) {
		push(@{$extras{$tab[0]}}, $tab[$_]);
	}
}
close(IN);

open(OUT, ">$out");
print OUT "GENE\tCHROM\tSCAFF\tSTART\tSTOP\t$headers\tPEAK?\n";
open(GENE, $windGeneFile);
while(<GENE>) {
	my @tab = split(/\s+/, $_);
	my $others = "\t";
	if(defined $extras{$tab[4]}) {
		$others .= join("\t", @{$extras{$tab[4]}});
	}
	else {
		$others="";
		for(@columns) {
			$others.="\tNA";
		}
	}

	print OUT $tab[4]."\t".$tab[0]."\t".$tab[1]."\t".$genes{$tab[4]}{'start'}."\t".$genes{$tab[4]}{'stop'}.
			$others."\t".$windows{$tab[1]}{$tab[2]}{'peak'}."\n";
}
close(IN);
close(OUT);
