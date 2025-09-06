#!/usr/bin/perl


# # # # # #
# divideLastzFile.pl
# written by Linnéa Smeds		            31 May 2011
# =====================================================
# Takes an outputfile from lastz and sperates it into 
# one file for each chromosome that are given in a list
# as input). The new files are called prefix_chr*.out.
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $infile = $ARGV[0];	        #Lastz output
my $chromList = $ARGV[1];	    #list with all chromosomes in the lastz file
my $prefix = $ARGV[2];          #output prefix


#Save all chromosomes in an array
my @chromosomes;
open(IN, $chromList);
while(<IN>) {
	chomp($_);
	push(@chromosomes, $_);
}
close(IN);

foreach my $chr (@chromosomes) {
    
    my $ch = $chr;
    $ch =~ s/chr//;
    $ch =~ s/random/_random/;

    system("awk '(\$1==\"$ch\"){print}' $infile |sort -k2n >$prefix"."_$chr.out");
}
