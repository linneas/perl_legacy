#!/usr/bin/perl

# # # # # #
# removeGivenPositionsFromList.pl
# written by Linnéa Smeds                     July 2013
# =====================================================
# Remove positions from a list (e.g. a tsv file) that
# overlaps with regions in a given bed file (repeats,
# for example).
# Position list can have any number of columns but 
# must have sequence name in col 1 and pos in col 2. 
# =====================================================
# Usage: perl removeGivenPositionsFromList.pl <pos file> 
#			<bed regions> <outfile>

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $POSITION = $ARGV[0];
my $BED = $ARGV[1];
my $OUTPUT = $ARGV[2];

# Save all the regions in a hash
my %regions = ();
open(IN, $BED);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	for(my $i=$tab[1]; $i<=$tab[2]; $i++) {
		$regions{$tab[0]}{$i}=1;
	}
}
close(IN);

# Go through positions and print if
# they are not in the hash
open(OUT, ">$OUTPUT");
open(POS, $POSITION);
while(<POS>) {
	my @tab = split(/\s+/, $_);
	unless(defined $regions{$tab[0]}{$tab[1]}) {
		print OUT $_;
	}
}
close(POS);
close(OUT);





