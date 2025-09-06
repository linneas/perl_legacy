#!/usr/bin/perl

# makeNewSAMofEndsOnly.pl
# written by Linnéa Smeds                       15 May 2012
# ==========================================================
# takes a SAM file with pairs mapping on different scaffolds
# only, and saves only lines where both reads map close to
# the end. Also needs a length file with all scaffolds and a
# close-to-end-threshold.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $sam = $ARGV[0];
my $LengthFile = $ARGV[1];
my $limit = $ARGV[2];
my $output = $ARGV[3];

my $lengthThres = 14250;

# save all lengths in hash
my %lengths = ();
open(IN, $LengthFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	if($tab[1]>$lengthThres) {
		$lengths{$tab[0]}=$tab[1];
	}
}
close(IN);


#Open outfile
open(OUT, ">$output");

# Go through the SAM and checks closeness to End
open(SAM, $sam);
while(<SAM>) {
	my @tab = split(/\s+/,$_);
	
	if(defined$lengths{$tab[2]} && defined $lengths{$tab[6]}) {
		if(($tab[3]<$limit || $tab[3]>$lengths{$tab[2]}-$limit) && ($tab[7]<$limit || $tab[7]>$lengths{$tab[6]}-$limit)) {
			print OUT $_;
		}
	}
}
