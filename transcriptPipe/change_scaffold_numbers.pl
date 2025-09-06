#!/usr/bin/perl


# # # # # #
# change_scaffold_numbers.pl
# written by Linnéa Smeds 26 03 2010
# ===================================================
# Takes a .scafSeq file with scaffolds and singletons
# and changes the names and numbers so all sequences
# are called "contig" plus a number (ascending order
# starting from 1). Takes the scaffold file, the new
# file name and a mapping file name as input param.
# ===================================================
# Usage: 

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $scaffold_file = $ARGV[0]; 	
my $output = $ARGV[1];		
my $mapping_file = $ARGV[2];

open(MAP, ">$mapping_file");
open(OUT, ">$output");

print MAP "old_scaffold\tnew_scaffold\n";

my $cnt = 1;

open(IN, $scaffold_file);
while(<IN>) {
	if($_ =~ m/^>/) {
		print OUT ">contig".$cnt."\n";
		chomp($_);
		print MAP $_."\tcontig".$cnt."\n";
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
