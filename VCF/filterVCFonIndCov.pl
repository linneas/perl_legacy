#!/usr/bin/perl

# filterVCFOnIndCov.pl  	
# written by Linnéa Smeds,                   9 May 2014
# NOTE! This script is modified to also handle haploid
# vcf files.
# =====================================================
# Takes a file with individual name, mean autosomal cov
# and column number (real number, script takes col-1)
# and prints only lines where at least a given number of
# individuals have a coverage that lies within the 
# expected range 
# (>Exp/2 && <2*Exp, where Exp=Autosomal coverage/2).
# NOTE! The file with individuals must be exactly the
# same as for the vcf file (doesn't work to give a full
# list with all pop if vcf only contains one pop).
# =====================================================
# usage perl filterVCFOnIndCov.pl file.vcf indcov.txt 7


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $MEANCOV = $ARGV[1];	# Three columns:ind name, mean coverage and column number
my $MININD= $ARGV[2];	# At least this many individuals needs to be covered

# Save the individual coverages in a hash
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
				if($dp<=$hash{$ind}{'mean'} && $dp>=$hash{$ind}{'mean'}/4) {
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
