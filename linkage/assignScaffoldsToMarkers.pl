#!/usr/bin/perl

# # # # # #
# assignScaffoldsToMarkers.pl
# written by Linnéa Smeds                   5 July 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $markers2scaff = $ARGV[0];	#
my $linkageMap = $ARGV[1];	#


# Save all lengths in a hash
my %markers = ();
open(IN, $markers2scaff);
while(<IN>) {
	my ($marker, $scaff, $status) = split(/\s+/, $_);
	$marker =~ s/\*//;
	$markers{$marker}=$scaff;
} 
close(IN);


# Go through the text file
open(IN, $linkageMap);
while(<IN>) {
	my ($chrom,$marker,$pos) = split(/\s+/, $_);
	if(defined $markers{$marker} && $markers{$marker} ne "NA" && $markers{$marker} ne "DIFF") {
		print $chrom."\t".$marker."\t".$pos."\t".$markers{$marker}."\n";
	}
	else {
		print $chrom."\t".$marker."\t".$pos."\t-\n";
	}
}



