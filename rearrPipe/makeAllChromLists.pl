#!/usr/bin/perl

# # # # # #
# makeAllChromLists.pl		
# written by Linnéa Smeds                      13 Sept 2011
# ---------------------------------------------------------
# DESCRIPTION:
# Makes a concatenated file with for example segments or 
# scaffolds lists from all chromosomes in order, adding the
# chromosome name as a first column.

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $prefix = $ARGV[1];
my $suffix = $ARGV[2];
my $concatList = $ARGV[3];


open(OUT, ">$concatList");		#Initiating file

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND RUN THE DIFFERENT STEPS
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);

	my $file = $prefix.$chrom.$suffix;
	if (-e $file) {
		open(FILE, $file);
		while(my $line=<FILE>) {
			unless($line =~ m/#/) {
				print OUT $chrom."\t".$line;
			}
		}
		close(FILE);
	}
} 
close(IN);
close(OUT);
