#!/usr/bin/perl

# convertVCFtoFasta.allsites.withfiltCol.pl  	
# written by Linnéa Smeds,                  19 Feb 2018
# NOTE, right now it works only on haploid vcf files!
# =====================================================
# Modified from convertVCFtoFasta.pl, so that it looks
# at column 7 to see if the site PASS or not. For non-
# variant sites, it prints either the reference base 
# (if GT is 0) or N (if GT is ., OR something else - this
# might actually happen..). For varing sites it can
# print either all kinds of variation (indels, and mult
# variables), or only biallelic SNPs (set flags below)
# -in the latter case all fasta sequences will have the
# same length and can be treated as already aligned!
# =====================================================
# usage perl convertVCFtoFasta.pl file.vcf out.fst

use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $COVTHRES = $ARGV[1];
my $GQTHRES = $ARGV[2];
my $FASTA = $ARGV[3]; 	# Output fasta file

# Other settings:
my $FILTINDEL = "YES";
my $FILTMULT = "NO";

# Make hash to save all the sequences!
my %seqs = ();

# Counts
my ($multCnt, $indelCnt, $nonVarWithAltCnt, $passedSitesWithMultCnt, $filtCnt, $depthGQCnt)= (0,0,0,0,0,0);

# Go through vcf 
my $cnt=0;
open(IN, $VCFFILE);
while(<IN>) {
	if(/^#CHROM/)	{	
		my @tab=split(/\s+/, $_);
		for (my $i=9; $i<scalar(@tab); $i++) {
			$seqs{$i}{'name'}=$tab[$i];
			$seqs{$i}{'seq'}="";
		}
	}
	elsif($_ !~ m/##/) {
		my @tab=split(/\s+/, $_);

		# Set ref and alt alleles
		my $ref=$tab[3];
		my @alt=split(/,/, $tab[4]);

		# Check numbers of alt alleles
		my $num_alt=scalar(@alt);
		
		# If we want to filter for sites with more than two alleles:
		if($FILTMULT eq "YES") {
			if($num_alt>1) {
				$ref="N";
				for (my $i=0; $i<scalar(@alt); $i++) {
					$alt[$i]="N";
				}
				$multCnt++;
			}
		}
		
		# Check if we have an indel
		my $longest=0;
		foreach $a (@alt) {
			if(length($a)>$longest) {
				$longest=length($a);
			}
		}
		if(length($tab[3])>$longest) {
			$longest=length($tab[3]);
		}

		if($FILTINDEL eq "YES") {
			if($longest>1) {
				$ref="N";
				for (my $i=0; $i<scalar(@alt); $i++) {
					$alt[$i]="N";
				}
				$indelCnt++;
			}
		}


		if($tab[6] eq "PASS") {	# Variable sites that passed the thres
		#	print STDERR "look at pass site\n";
			for (my $i=9; $i<scalar(@tab); $i++) {
				my $add;
				my @a = split(/:/, $tab[$i]);

				if($a[0] eq ".") {	# missing -> ok
					$add="N";
				}
				else {	# If a site is not missing, check depth and GQ
					if($a[3]<$GQTHRES || $a[2]<$COVTHRES) {			# Depth or GQ is not fulfilled! 
						$add="N";
						$depthGQCnt++;
					}
					else {
						if($a[0] eq "0") {				# reference -> Ok
							$add=$ref;
						}	
						elsif($a[0] eq ".") {			# missing -> ok
							$add="N";
						}
						elsif($a[0] eq "1") {			# alternative (1) -> Ok
							$add=$alt[0];
						}	
						else {							# if there are more alt -> count
							my $index=$a[0]-1;
							$add=$alt[$index];
							$passedSitesWithMultCnt++;
						}
					}
				}
				$seqs{$i}{'seq'}.=$add;
			}
		}
		elsif($tab[6] eq ".") { # No filter tag => should be nonvariable
			
			for (my $i=9; $i<scalar(@tab); $i++) {
				my $add;
				my @a = split(/:/, $tab[$i]);
				if($a[0] eq ".") {			# missing -> ok
					$add="N";
				}
				else { 		# If a site is not missing, check depth and GQ
					if($a[3]<$GQTHRES || $a[2]<$COVTHRES) {			# Depth or GQ is not fulfilled!
						$add="N";
						$depthGQCnt++;
					}
					else {
						if($a[0] eq "0") {				# reference -> Ok
							$add=$ref;
						}	
						elsif($a[0] eq ".") {			# missing -> ok
							$add="N";
						}
						else {							# something else -> Set to N, count!
							$add="N";					
							$nonVarWithAltCnt++;
						}
					}
				}
				$seqs{$i}{'seq'}.=$add;
			}
		}
		else {		# variable site that didn't pass => change to N!
		#	print STDERR "look at hardfilt site\n";
			for (my $i=9; $i<scalar(@tab); $i++) {
				my $add="N";
				$seqs{$i}{'seq'}.=$add;
				$filtCnt++;
			}
		}
		$cnt++;
	}
}
close(IN);


# Go through hash and save fasta
open(FA, ">$FASTA");

foreach my $keys (sort {$a<=>$b} keys %seqs) {
	print FA ">".$seqs{$keys}{'name'}."\n";
	print FA $seqs{$keys}{'seq'}."\n";
}
close(FA);

print "Translated $cnt positions\n";
print "$multCnt sites were set to N because they were biallelic\n";
print "$indelCnt sites were set to N because they had length >1 (indels)\n";
print "$nonVarWithAltCnt sites were not reported as variable but still had alt alleles (set to N)\n";
print "$passedSitesWithMultCnt were reported as PASSED but still had more than one alt allele\n";
print "$filtCnt sites did not pass filters and were set to N.\n";
print "$depthGQCnt sites did not pass either depth or GQ threshold\n"; 

