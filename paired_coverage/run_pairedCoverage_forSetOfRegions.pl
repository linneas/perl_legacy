#!/usr/bin/perl

# run_pairedCoverage_forSetOfRegions.pl
# written by Linnéa Smeds                         July 2011
# =========================================================
# run the (prop)pairedCoverageFromBAM()-scripts for a set
# of regions defined in a list with scaffold name, start 
# and stop positions. Also give a min and max insert size
# and a surrounding area limit (all reads in region+/- this
# value will be used for calculating the paired cov.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $bam = $ARGV[0];
my $regions = $ARGV[1];
my $minIns = $ARGV[2];
my $maxIns = $ARGV[3];
my $surround = $ARGV[4];
my $output = $ARGV[5];

#Other parameters
my $script = "/bubo/home/h14/linnea/private/scripts/paired_coverage/PairedCoverageFromBAM_giveInsertAndRange.pl";
#ALT use "propPairedCoverageFromBAM_giveInsertAndRange.pl"

open(OUT, ">$output");
open(IN, $regions);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $scaf = $tab[0];
	my $start = $tab[1];
	my $end = $tab[2];
	
	my $tempfile = $scaf."_".$tab[1]."-".$tab[2].".temp";
	system("perl $script $bam $scaf $start $end $minIns $maxIns $surround $tempfile");

	my $totCov = 0;
	my $cnt = 0;
	open(RES, $tempfile);
	while(my $line=<RES>) {
		my @l = split(/\s+/, $line);
		$totCov+=$l[2];
		$cnt++;
	}
	my $meanCov = $totCov/$cnt;
	print OUT $scaf."\t".$start."\t".$end."\t".$meanCov."\n";
	if($meanCov<5) {
		print "$scaf\t$start\t$end\tCoverage less than 5!!!\n"; 
	}

	system("rm $tempfile"); 
}
close(IN);
close(OUT);
