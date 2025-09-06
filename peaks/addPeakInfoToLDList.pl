#!/usr/bin/perl


# addPeakinfoToLDList.pl		  	  
# written by Linnéa Smeds                              4 May 2012
# ------------------------------------------------------------------
# Takes a table with windows and peak info (seven columns, peak in
# last column) and add this to a list of SNP pairs (arbitrary no
# of columns, but demands scaffold name in first and positions in 
# the two following). Also calculates and adds the distance between
# SNPs, and the midpoint between them. 
# -----------------------------------------------------------------
# Usage: perl addPeakinfoToLDList.pl <PEAK TABLE> <SNP PAIRS> <OUT>
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $peakTable = $ARGV[0];
my $LDList = $ARGV[1];
my $outfile = $ARGV[2];

#Change the window size here:
my $windSize = 200000;

#Save peak information for each window
my %windows = ();
open(IN, $peakTable);
<IN>;
while(<IN>) {
	my @tab = split(/\s+/, $_);	
	if($tab[6]==1) {
#		print "DEBUG: saving ".$tab[1]." ".$tab[2]."\n";
		$windows{$tab[1]}{$tab[2]}=$tab[6];	
	}
}
close(IN);

# Open out file handle and print header
open(OUT, ">$outfile");
print OUT "SCAF	POS1	POS2	R2	DIST	MIDPOINT	PEAK?\n";

#Go through the SNP list and add dist, mid-point and peak info 
open(LD, $LDList);
while(<LD>) {
	unless(/CHR/) {
		chomp($_);
		my @tab = split(/\s+/, $_);

		my $dist=$tab[2]-$tab[1];
		my $midpoint=int(($tab[2]+$tab[1])/2);
	
		#Find the nearest window starting point
		my $wstart=int($midpoint/$windSize)*$windSize+1;
#		print "DEBUG: midpoint = $midpoint, windsize=$windSize, wstart=$wstart\n";
	
		my $peak = 0;
		if(defined $windows{$tab[0]}{$wstart}) {
#			print "DEBUG: ".$tab[0]." has a peak at $wstart\n";
			$peak = 1;
		}
		print OUT $_."\t".$dist."\t".$midpoint."\t".$peak."\n";
	}
}
close(LD);

