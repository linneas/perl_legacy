#!/usr/bin/perl

# extractSeqFromBed.pl
# written by Linnéa Smeds                       26 Nov 2013
# =========================================================
# Takes a bed file and a list of scaffolds, and extract all
# scaffolds that are present on the list. This works also 
# when the scaffolds have semi-redundant names, like scaf4
# and scaf44 (when for example grep -f list doesn't work). 
# =========================================================

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $BED = $ARGV[0];
my $LIST = $ARGV[1];

# save all wanted sequence names in hash
my %names = ();
open(IN, $LIST);
while(<IN>) {
	chomp($_);
	$names{$_}=0;
}
close(IN);


# Go through the SAM and checks closeness to End
open(BED, $BED);
while(<BED>) {
	my @tab = split(/\s+/,$_);
	if(defined $names{$tab[0]}) {
		print $_;
	}
}
close(BED);

