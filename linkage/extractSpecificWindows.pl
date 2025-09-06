#!/usr/bin/perl


# # # # # #
# extractSpecificWindows.pl
# written by Linnéa Smeds		       Feb 2012
# =====================================================
# Takes a table with chromosome, scaffold, windows and 
# any additional information, and another file with
# the wanted windows (scaffold and window start can be
# in any given column, given below). Only the wanted
# rows from the first file is printed to a new file.
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $table = $ARGV[0];	 
my $specWindFile = $ARGV[1];
my $outfile = $ARGV[2];	   
my $scafCol = 1;          
my $windCol = 2;

my %windows = ();
open(IN, $specWindFile);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$windows{$tab[$scafCol]}{$tab[$windCol]}=1;
}
close(IN);

my ($rmCnt, $totCnt)=(0,0);
open(OUT, ">$outfile");
open(TAB, $table);
while(<TAB>) {
	my @tab = split(/\s+/, $_);
	if(defined $windows{$tab[1]}{$tab[2]}) {
		print OUT $_;
	}
	else {
		$rmCnt++;
		print "Removed: $_";
	}
	$totCnt++;
}
close(TAB);
close(OUT);

print "$rmCnt out of $totCnt rows removed.\n";
