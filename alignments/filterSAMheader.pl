#!/usr/bin/perl

# filterSAMheader.pl
# written by Linnéa Smeds                        26 Nov 2013
# ==========================================================
# takes a SAM file header and a list of scaffolds, and save
# only the header sequences that are present on the list.
# =========================================================


use strict;
use warnings;

# Input parameters
my $SAMH = $ARGV[0];
my $LIST = $ARGV[1];

my %names = ();
open(IN, $LIST);
while(<IN>) {
 chomp($_);
 $names{$_}=1;
}
close(IN);

# Go through the SAM header
open(SAM, $SAMH);
while(<SAM>) {
	if(/^\@SQ/) {
		my @tab = split(/\t/, $_);
		$tab[1]=~ s/SN://;
		if(defined $names{$tab[1]}) {
			print $_;
		}
	}
	else {
		print $_;
	}
}
close(SAM);
