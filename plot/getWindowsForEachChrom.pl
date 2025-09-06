#!/usr/bin/perl

# # # # # #
# getWindowsForEachChrom.pl
# (a modification of divideWindowsOnLinkageGroups.pl)
# written by Linnéa Smeds, Nov 2011
# =========================================================
# Takes a scaffold list file with 5 columns (chrom, scaffold,
# length, order, and some info), and a window-list file
# with a non defined number of windows and columns and 
# prints the lines belonging to each above listed scaffold to
# a new file ordered after the list file (ie ordered as the
# FC genome).
# =========================================================


use strict;
use warnings;

#Input parameters
my $scafList = $ARGV[0];	#Five columns (chrom, scaff, length, sign, comment)
my $windList = $ARGV[1];	#Arbitary number of columns (but scaffold name first)
my $out = $ARGV[2];

#Save all scaffolds
my %scaffolds = ();
open(IN, $scafList);
my $cnt = 1;
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	$scaffolds{$tabs[1]}{'order'} = $cnt;
	$scaffolds{$tabs[1]}{'sign'} = $tabs[3];
	$scaffolds{$tabs[1]}{'chr'} = $tabs[0];
	$scaffolds{$tabs[1]}{'array'} = [];
	$cnt++;
}
close(IN);

#Go through the window list
open(IN, $windList);
while(<IN>) {
	unless(/#/) {
		my @tab = split(/\s+/, $_);
		if(defined $scaffolds{$tab[0]}) {
			push(@{$scaffolds{$tab[0]}{'array'}}, "$_");
		}
	}
}
close(IN);


open(OUT, ">$out");
foreach my $key (sort {$scaffolds{$a}{'order'}<=>$scaffolds{$b}{'order'}} keys %scaffolds){
	if($scaffolds{$key}{'sign'} eq "-") {
		@{$scaffolds{$key}{'array'}}=reverse(@{$scaffolds{$key}{'array'}});
	}
	foreach(@{$scaffolds{$key}{'array'}}) {
		print OUT $scaffolds{$key}{'chr'} ."\t" . $_;
	}
}
close(OUT);

