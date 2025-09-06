#!/usr/bin/perl

# # # # # #
# reverseComplement.pl
# written by Linnéa Smeds 20 oct 2010
# ====================================================
# 
# ====================================================
# Usage: perl

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $DNAstring = $ARGV[0];

my $output = "";

my @a = split(//, $DNAstring);

for(@a) {
	$_ =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
	$output = $_ . $output;
}

print $output."\n";
