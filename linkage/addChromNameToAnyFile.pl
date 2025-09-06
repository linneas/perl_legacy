#!/usr/bin/perl


# # # # # #
# addChromNameToAnyFile.pl
# written by Linnéa Smeds		       Oct 2011
# =====================================================
# Takes a list of chromosomes, and goes through all
# files with a certain prefix and suffix, printing
# them to a merged file with the chromosome name as 
# a first column.
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $ChromList = $ARGV[0];	 
my $prefix = $ARGV[1];	   
my $suffix = $ARGV[2];          
my $output = $ARGV[3];

open(OUT, ">$output");

open(LST, $ChromList);
while(<LST>) {
	my $chr = $_;
	chomp($chr);

	my $infile = $prefix.$chr.$suffix;

	print "tittar på filen $infile\n";
	open(IN, $infile);
	while(my $line = <IN>) {
		print OUT "Chr".$chr."\t".$line;
	}
	close(IN);
}
close(LST);
close(OUT);
