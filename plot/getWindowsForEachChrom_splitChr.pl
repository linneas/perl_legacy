#!/usr/bin/perl

# # # # # #
# getWindowsForEachChrom_splitChr.pl
# (a modification of getWindowsForEachChrom.pl from Nov 2011)
# written by Linnéa Smeds, sept 2012
# =========================================================
# Takes a linked scaffold list file with 7 columns (chrom, 
# scaffold, length, order, type, color and link info), a map
# file with info about the splits, and a a window-list file
# with a non defined number of windows and columns and 
# prints the lines belonging to each above listed scaffold to
# a new file ordered after the list file (ie ordered as the
# FC genome).
# =========================================================


use strict;
use warnings;

#Input parameters
my $scafList = $ARGV[0];	#Five columns (chrom, scaff, length, sign, color, link, comment)
my $splitMap = $ARGV[1];
my $windList = $ARGV[2];	#Arbitary number of columns (but scaffold name first)
my $out = $ARGV[3];

open(OUT, ">$out");

#Save the splits
my %split = ();
open(IN, $splitMap);
while(<IN>) {
	my ($scaf, $old, $start, $stop) = split(/\s+/, $_);
	$split{$scaf}{'old'}=$old;
	$split{$scaf}{'start'}=$start;
	$split{$scaf}{'stop'}=$stop;
}
close(IN);

#Save all scaffolds that will be used
my %scaffolds = ();
open(IN, $scafList);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	if($tabs[1]=~ m/\./) {
			$tabs[1] =~ s/\.\d//;
		}
	$scaffolds{$tabs[1]}=1;
}
close(IN);

#Save all windows that will be used
my %windows = ();
open(IN, $windList);
while(<IN>) {
	unless(/#/) {
		my @tab = split(/\s+/, $_);
		my $scaffold = shift @tab;
		my $start = shift @tab;
		my $end = shift @tab;
		if(defined $scaffolds{$scaffold}) {
			$windows{$scaffold}{$start}{'end'}=$end;
			push(@{$windows{$scaffold}{$start}{'rest'}}, @tab);	
		}
	}
}
close(IN);


open(IN, $scafList);
my $cnt = 1;
while(<IN>) {
	my @tab = split(/\s+/, $_);

	my($start, $stop) = (1, $tab[2]);

	if(defined $split{$tab[1]}) {
		$start = $split{$tab[1]}{'start'};
		$stop = $split{$tab[1]}{'stop'};
	}

	my $scaf = $tab[1];
	if($scaf=~ m/\./) {
		$scaf =~ s/\.\d//;
	}
	
	foreach my $keys (sort keys %{$windows{$scaf}}) {
		if($keys>=$start && $windows{$scaf}{$keys}{'end'}<=$stop) {
			print OUT $tab[0]."\t".$keys."\t".$windows{$scaf}{$keys}{'end'}."\t".$windows{$scaf}{$keys}{'rest'}."\n";
		}
	}
}
close(IN);

