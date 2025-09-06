#!/usr/bin/perl

# extractReadsWithoutMDmismatchFromSAM.pl
# written by Linnéa Smeds                        2 Juli 2013
# ==========================================================
# takes a SAM file and save only reads that have no mismatch
# according to the MD flag.
# =========================================================


use strict;
use warnings;

# Input parameters
my $sam = $ARGV[0];

# Go through the SAM and checks MDtag
open(SAM, $sam);
while(<SAM>) {
	if(/^@/) {
		print $_;
	}
	else {
		unless($_ =~ m/MD:Z:\d+.*[A-Z]+\d+/) {
			print $_;
		}
	}
}
close(SAM);
