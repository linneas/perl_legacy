#!/usr/bin/perl

# mismatchFilterSAM.pl
# written by Linnéa Smeds                         4 Dec 2013
# ==========================================================
#
# =========================================================


use strict;
use warnings;

# Input parameters
my $sam = $ARGV[0];
my $maxdist = $ARGV[1];

# Go through the SAM and checks NM-tag
open(SAM, $sam);
while(<SAM>) {
	if(/^@/) {
		print $_;
	}
	else {
		if($_ =~ m/NM:i:(\d+)/) {
			my $dist=$1;
			if($dist<=$maxdist) {
				print $_;
			}
		}
	}
}
close(SAM);

