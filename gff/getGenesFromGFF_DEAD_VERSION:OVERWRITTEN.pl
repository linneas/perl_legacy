#!/usr/bin/perl

# # # # # # 
# getGenesFromGFF.pl
# written by Linnéa Smeds                        21 Nov 2011
# ----------------------------------------------------------
# Description:
# Takes a list of genes and extracts them from a GFF file
# ----------------------------------------------------------
# Usage:
#

use strict;
use warnings;


# Input parameters
my $GFF = $ARGV[0];
my $LIST = $ARGV[1];
my $OUT = $ARGV[2];

my %genes = ();
open(IN, $LIST);
while(<IN>) {
	chomp($_);
	$genes{$_}=1;
}
close(IN);

open(OUT, ">$OUT");
open(IN, $GFF);
while(<IN>) {
	my @t = split(/\t/, $_);
	if(defined $wanted{$t[0]}{$t[1]}) {
		print OUT $_;
	}
}
close(IN);
close(OUT);


