#!/usr/bin/perl

my $usage="
# # # # # #
# meanAndMedianCoverage_genomeCoverageBed.pl
# written by Linnéa Smeds                    2 Feb 2017
# =====================================================
# Takes output from genomicCoverageBed together with a
# list of wanted scaffolds, and calculates the mean and
# median coverage based on the histogram. 
 
#
# INPUT:
# 1) list of wanted scaffolds
# 2) BEDTools genomeCoverageBed file
# 3) Name of output
# =====================================================
# USAGE:
";


use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $SCAFLIST = $ARGV[0];	# List of wanted chromosomes + their lengths
my $COVFILE = $ARGV[1];	# Coverage file
my $OUTPUT = $ARGV[2];	# name used in output file


# Go through scaffolds and save wanted and in a hash
my %wanted=();
open(IN, $SCAFLIST);
while(<IN>) {
	my @t=split(/\s+/,$_);
	$wanted{$t[0]}=0;
}
close(IN);

# Create a hash for saving sums (needed for median calc)
my %nsum = ();

# Create a hash for results:
my %res = ();

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Go through the coverage file
my $prev="";
open(IN, $COVFILE);
my $cnt=0;
my ($sum, $n);
while(<IN>) {
	my @t=split(/\s+/, $_);

	# Continuing an already started scaffold
	if($t[0] eq $prev) {
		$sum+=$t[1]*$t[2];
		$n+=$t[2];
		$nsum{$t[0]}{$t[1]}=$n;
	}
	# New scaffold!
	else {	
		# First save the old one, if any:
		if($prev ne "") {
			$cnt++;
			$res{$cnt}{"scaf"}=$prev;
			$res{$cnt}{"sum"}=$sum;
			$res{$cnt}{"n"}=$n;
			$prev="";			#To avoid printing the same line multiple times 
								#if there are several unwanted in a row!
		}
		# Then look at the new one
		if(defined $wanted{$t[0]}) {
			$n=$t[2];
			$sum=$t[1]*$t[2];
			$nsum{$t[0]}{$t[1]}=$n;
			$prev=$t[0];
		}
	}
}
close(IN);
# Save the last one (if not empty)!
if($prev ne "") {
	$cnt++;
	$res{$cnt}{"scaf"}=$prev;
	$res{$cnt}{"sum"}=$sum;
	$res{$cnt}{"n"}=$n;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Open output: 
open(OUT, ">$OUTPUT");

# Go through all scaffolds in result file and calc mean and median
foreach my $key (sort {$a<=>$b} keys %res) {
	my $mean = $res{$key}{"sum"}/$res{$key}{"n"};
	my $median=0;
	foreach my $sub (sort {$a<=>$b} keys %{$nsum{$res{$key}{"scaf"}}}) {
		if($nsum{$res{$key}{"scaf"}}{$sub}>=$res{$key}{"n"}/2) {
			$median=$sub;
			last;
		}
	}
	print OUT $res{$key}{"scaf"}."\t".$median."\t".$mean."\n";
#	print STDERR "DEBUG: $key:".$res{$key}{"scaf"}."\tSum is ".$res{$key}{"sum"}.", n is ".$res{$key}{"n"}."\n";
}


