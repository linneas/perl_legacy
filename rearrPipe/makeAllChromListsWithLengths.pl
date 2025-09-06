#!/usr/bin/perl

# # # # # #
# makeAllChromListsWithLengths.pl		
# written by Linnéa Smeds                       27 Nov 2011
# ---------------------------------------------------------
# DESCRIPTION:
# Makes a concatenated file with for example segments or 
# scaffolds lists from all chromosomes in order, adding the
# chromosome name as a first column and the length after the
# scaffold name.

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $prefix = $ARGV[1];
my $suffix = $ARGV[2];
my $lengthFile = $ARGV[3];
my $concatList = $ARGV[4];

my %lengths = ();
open(IN, $lengthFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$lengths{$tab[0]}=$tab[1];
}


open(OUT, ">$concatList");

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND MAKE A NEW LIST
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);

	my $file = $prefix.$chrom.$suffix;
	if (-e $file) {
		open(FILE, $file);
		while(my $line=<FILE>) {
			unless($line =~ m/#/) {
				my @t = split(/\s+/, $line);
				print OUT $chrom."\t".$t[0]."\t".$lengths{$t[0]}."\t".$t[1]."\n";
			}
		}
		close(FILE);
	}
} 
close(IN);
close(OUT);
