#!/usr/bin/perl

# processFakeVCFwithMicrosatLengths.pl  	
# written by Linnéa Smeds,                  14 Mar 2016
# =====================================================
# Takes a "fake vcf" file with chrom, pos, reflength + 
# genotypes for all individuals (no cov or qual, only
# the length, or length1/length2 if heterozygous).
#
# Returns lines that have not more than a certain 
# number of different allelotypes, or more than a certain
# number of missing sites (both given as input).
#
# =====================================================
# usage: perl processFakeVCFwithMicrosatLengths.pl  	

use strict;
use warnings;
my $time=time;


# Input parameters
my $VCF=$ARGV[0];	# 3+N columns: chr pos, reflen, + any number of genotypes
my $MAXGT=$ARGV[1];	# Maximum number of allele types that can be present
my $MINGT=$ARGV[2];	# Minimum number of allele types (only one is not informative)
my $MAXMIS=$ARGV[3];# maximum number of missing genotypes per site
my $OUT = $ARGV[4];	# Filtered fake VCF file


# Open outfile handle
open(OUT, ">$OUT");


print STDERR "Go through VCF like file...\n";
my ($cnt, $savecnt)=(0,0);
open(IN, $VCF);
while(<IN>) {
	if(/^#/) {
		print OUT;
	}
	else {
		my @t = split(/\s+/, $_); 
		my %alleles=();
		my $miss=0;
		for(my $i=3; $i<scalar(@t); $i++) {
			if($t[$i] eq ".") {
				$miss++;
			}
			elsif($t[$i] =~ m/\//){
				my ($a, $b)=split(/\//, $t[$i]);
				$alleles{$a}=1;
				$alleles{$b}=1;
			}
			else {
				$alleles{$t[$i]}=1;
			}
		}
		my $diffTypes=scalar keys %alleles;
		if ($diffTypes<=$MAXGT && $diffTypes>=$MINGT && $miss<=$MAXMIS) {
			print OUT;
			$savecnt++;
		}
		$cnt++;
	}
}
close(IN);
print STDERR "...Processed $cnt lines and saved $savecnt positions.\n";


$time=time-$time;
print STDERR "Total time elapsed: $time sec\n";
