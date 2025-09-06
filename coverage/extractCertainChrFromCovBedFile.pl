#!/usr/bin/perl

my $usage="
# # # # # #
# summarizeCovBedFromChrFiles.pl
# written by Linnéa Smeds                   25 Jan 2017
# =====================================================
# Takes output from genomicCoverageBed (BEDTools) and a
# list of wanted chromosomes/scaffolds (with lengths), 
# extract them from the file and merge them into a 
# combined histogram.
 
#
# INPUT:
# 1) list of wanted chromosomes+lengths
# 2) BEDTools genomeCoverageBed file
# 3) name of combined sequence (ex \"autosome\")
#
# =====================================================
# USAGE: perl summarizeCovBedFromChrFiles.pl <chrlist> \
#			<coverageFile> <name>
# Example:	 perl summarizeCovBedFromChrFiles.pl autosomes.txt \
#			allchr.coverage autosomal >Autosomalfile.coverage
";


use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $CHRLIST = $ARGV[0];	# List of wanted chromosomes + their lengths
my $COVFILE = $ARGV[1];	# Coverage file
my $NAME = $ARGV[2];	# name used in output file


# Go through chromosomes and in a hash
my %chr=();
my $totlen=0;
open(CHR, $CHRLIST);
while(<CHR>) {
	my @t=split(/\s+/,$_);
	$chr{$t[0]}=$t[1];
	$totlen+=$t[1];
}

# Create a hash for all coverage values
my %hash = ();
 
# Go through the coverage file
open(IN, $COVFILE);
while(<IN>) {
	my @t=split(/\s+/, $_);
	# If sequence name exists in the list, add it
	if(defined $chr{$t[0]}) {
#		print STDERR "Value ".$t[0]." is on the list\n";
		if(exists $hash{$t[1]}) {
#			print STDERR "Value ".$t[1]." is already in the hash\n";
			$hash{$t[1]}+=$t[2];
		}
		else {
#			print STDERR "Value ".$t[1]." is not in the hash, initilizing with ".$t[2]."\n";
			$hash{$t[1]}=$t[2];
		}
	}
}

# Go through the hash and print
my $maxcov = max keys %hash;

for(my $i=0; $i<=$maxcov; $i++) {
	if(defined $hash{$i}) {
		print $NAME."\t".$i."\t".$hash{$i}."\t".$totlen."\n";
	}
	else {
		print $NAME."\t".$i."\t0\t".$totlen."\n";
	}
}


