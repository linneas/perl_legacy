#!/usr/bin/perl

# # # # # #
# getSNPsForEachChrom.pl
# written by Linnéa Smeds, Oct 2012
# =========================================================
# Takes a scaffold list file with 5 or more columns (chrom, 
# scaffold, length, order, and some info), and list with
# SNPs for each scaffold (doesn't have to be sorted).
# Prints both a list of all SNPs sorted according to the
# scaffold list, and a summary of the number of SNPs for 
# a given window size.
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

