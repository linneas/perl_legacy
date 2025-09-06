#!/usr/bin/perl

# filterVCFOnIndCov_males.pl  	
# written by Linnéa Smeds,                   9 May 2014
# Modified to use the expected=autosomal cov (for males
# that should have the same coverage for all chrom) 
# NOTE! This script is modified to also handle haploid
# vcf files.
# =====================================================
# Saves lines if more than X individuals have coverage
# between AutosomalCov/2 and 2*AutosomalCov
# (See original for more)
# =====================================================
# usage perl filterVCFOnIndCov.pl file.vcf indcov.txt 7


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $MEANCOV = $ARGV[1];	# Three columns:ind name, mean coverage and column number
my $MININD= $ARGV[2];	# At least this many individuals needs to be covered

# Save the individual covearges in a hash
my %hash = ();
open(IN, $MEANCOV);
while(<IN>) {
	my @tab=split(/\s+/, $_);
	$hash{$tab[0]}{'mean'}=$tab[1];
	$hash{$tab[0]}{'col'}=$tab[2]-1;
}
close(IN);

# Go through vcf 
open(IN, $VCFFILE);
while(<IN>) {
	if(/^#/){
		print;
	}
	else {
		my @tab=split(/\s+/, $_);
		my $approved=0;
		foreach my $ind (keys %hash) {
#			print STDERR "DEBUG ".$tab[0].": pos".$tab[1].": tab is: ".$tab[$hash{$ind}{'col'}]."\n";
			unless($tab[$hash{$ind}{'col'}] eq "./." || $tab[$hash{$ind}{'col'}] eq ".") {
#				print STDERR "DEBUG ".$tab[0].": pos".$tab[1].": look at $ind\n";
				my @a = split(/:/, $tab[$hash{$ind}{'col'}]);
				my $dp=$a[2];
#				print STDERR "DEBUG ".$tab[0].": pos".$tab[1].": depth is $dp\n";
				if($dp<=$hash{$ind}{'mean'}*2 && $dp>=$hash{$ind}{'mean'}/2) {
					$approved++;
				}
			}
		}

		if($approved>=$MININD) {
			print;
		}
	}
}
close(IN);
