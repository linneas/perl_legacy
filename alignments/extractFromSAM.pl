#!/usr/bin/perl

# extractFromSAM.pl
# written by Linnéa Smeds                         4 Dec 2013
# ==========================================================
#
# =========================================================


use strict;
use warnings;

# Input parameters
my $sam = $ARGV[0];
my $readList =$ARGV[1];

# Save all reads
my %reads = ();
open(IN, $readList);
while(<IN>) {
	chomp($_);
	$reads{$_}=1;
}

# Go through the SAM and checks MDtag
open(SAM, $sam);
while(<SAM>) {
	my @tab=split(/\s+/, $_);
	if(defined $reads{$tab[0]}) {
		print $_;
	}
}
close(SAM);
