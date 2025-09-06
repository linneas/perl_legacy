#!/usr/bin/perl

# indCov_from_gzpileupDir.pl  	
# written by Linnéa Smeds,                30 March 2012
# =====================================================
# 
# =====================================================
# usage perl


use strict;
use warnings;

# Input parameters
my $DIR = $ARGV[0];
my $fileExtn = $ARGV[1];
my $output = $ARGV[2];

my $scafStart = 1;
my $scafEnd = 6626;

for(my $i=$scafStart; $i<=$scafEnd; $i++) {

	my $scaffold = $i;
	while(length($scaffold)<5) {
		$scaffold = "0".$scaffold;
	}
	$scaffold = "S".$scaffold;

	my $fileName = $scaffold.$fileExtn;

	if(-e "$DIR/$fileName") {
		open(IN, "gunzip -c $DIR/$fileName |");
		while(<IN>) {
			my @tab = split(/\s+/, $_); 

			for($i=9; $i<$#tab; $i++) {


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
