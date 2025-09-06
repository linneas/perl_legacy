#!/usr/bin/perl


# # # # # #
# addChromNameAndConcatSepFiles.pl
# written by Linnéa Smeds		       Oct 2011
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
my $Chrom2LinkList = $ARGV[0];	 
my $prefix = $ARGV[1];	   
my $suffix = $ARGV[2];          
my $output = $ARGV[3];

open(OUT, ">$output");

open(LST, $Chrom2LinkList);
while(<LST>) {
	my ($chr, $link) = split(/\s+/, $_);

	my $infile = $prefix.$link.$suffix;
	print "tittar på filen $infile\n";
	open(IN, $infile);
	while(my $line = <IN>) {
		print OUT "Chr".$chr."\t".$line;
	}
	close(IN);
}
close(LST);
close(OUT);
