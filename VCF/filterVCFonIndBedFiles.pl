#!/usr/bin/perl

# maskVCFOnIndBedFiles.pl  	
# written by Linnéa Smeds,                   3 May 2018
# =====================================================
# Takes a vcf file and a directory with bedfiles of 
# regions that 



# This is a modification of filterVCFOnIndCov.pl that
# keeps all the lenes (positions) in the original file,
# but replace the GT for "." or "./." if the coverage
# criteria is not fulfilled.
# The coverage must be between Exp/2 && 2*Exp, where 
# Exp=Autosomal coverage/2.
# NOTE! The file with individuals must be exactly the
# same as for the vcf file (doesn't work to give a full
# list with all pop if vcf only contains one pop).
#
# NOTE2: This script can take a full vcf file (not only
# SNP-positions) while the original can't.
# =====================================================
# usage perl filterVCFOnIndCov.pl file.vcf indcov.txt type


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $MEANCOV = $ARGV[1];	# Three columns:ind name, mean coverage and column number
my $TYPE= $ARGV[2];	# haploid or diploid

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
				my $dp=$a[1];
				if($dp=~m/,/) {
					$dp=$a[2];
				}
#				print STDERR "DEBUG ".$tab[0].": pos".$tab[1].": depth is $dp\n";
				unless($dp<=$hash{$ind}{'mean'} && $dp>=$hash{$ind}{'mean'}/4) {
					if($TYPE eq "haploid") {
						$tab[$hash{$ind}{'col'}]=".";
					}
					elsif($TYPE eq "diploid") {
						$tab[$hash{$ind}{'col'}]="./.";
					}
					else {
						die "Third input must be \"haploid\" or \"diploid\"\n";
					}
				}
			}
		}
		print join("\t", @tab)."\n";
	}
}
close(IN);
