#!/usr/bin/perl

# # # # # #
# changeFastaHeaders_simple.pl
# written by Linnéa Smeds 26 03 2010, mod 19 07 2012
# ===================================================
# Take a fasta file and change the headers to a given
# prefix + a number (disregarding of the original 
# names).
# ===================================================
# Usage: 

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $FASTA = $ARGV[0]; 	
my $prefix = $ARGV[1];	
my $OUT = $ARGV[2];

# Adding any zeros at the start?
my $numLen = 5;


# Outputfiles
my $OUTMap = $OUT.".mapping";
open(MAP, ">$OUTMap");
open(OUT, ">$OUT");

print MAP "OLD_NAME\tNEW_NAME\n";

my $cnt = 1;

open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/) {
		my $num = $cnt;
		while(length($num)<$numLen) {
			$num = "0".$num;
		}
		print OUT ">$prefix".$num."\n";
		chomp($_);
		print MAP $_."\t$prefix".$num."\n";
		$cnt++;
	}
	else {
		if ( $_ ne "\n") {
			print OUT $_;
		}
	}
}

$time = time-$time;
print "Time elapsed: $time sec\n";
