#!/usr/bin/perl

# convertVCFtoGTtable_withThres.pl  	
# written by Linnéa Smeds,                   16 May 2014
# =====================================================
# Converts a VCF file to a table with bases for each
# individual. If the coverage is outside of the expected,
# print "N" instead.
# =====================================================
# usage perl convertVCFtoGTtable.pl file.vcf indcov.txt 7


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];		#The vcf file with all positions
my $MEANCOV = $ARGV[1];		# Three columns:ind name, mean coverage and column number
my $HZREPORT = $ARGV[2]; 	#A file where all positions with at least one heterozygot ind are saved

open(HZOUT, ">$HZREPORT");

	
#Save the individual covearges in a hash
my %hash = ();
open(IN, $MEANCOV);
while(<IN>) {
	my @tab=split(/\s+/, $_);
	my $colno=$tab[2]-1;
	$hash{$colno}{'name'}=$tab[0];
	$hash{$colno}{'mean'}=$tab[1];
}
close(IN);

# Go through vcf 
open(IN, $VCFFILE);
while(<IN>) {
	if(/^#CHROM/){
		my @tab = split(/\s+/, $_);
		my $outline=$tab[0]."\t".$tab[1];
		for (my $i=9; $i<scalar(@tab); $i++) {
			$outline.="\t".$tab[$i];
		}
		print $outline."\n";
	}
	elsif($_ !~ m/##/) {
		my @tab=split(/\s+/, $_);

		my $outline=$tab[0]."\t".$tab[1];
		my $hzFlag=0;

		for (my $i=9; $i<scalar(@tab); $i++) {
#			if($tab[$i] !~ m/:/) {
#				print STDERR "ERROR: Something wrong with line: $_";
#			}
			my @a = split(/:/, $tab[$i]);
			my $add="N";
			unless($tab[3] eq "N") {
				if($a[0] eq "0/0") {
					if(($tab[8] eq "GT:DP" && $a[1]<=$hash{$i}{'mean'} && $a[1]>=$hash{$i}{'mean'}/4) || 
						($tab[8]=~/^GT:AD/ && $a[2]<=$hash{$i}{'mean'} && $a[2]>=$hash{$i}{'mean'}/4)) {
						$add=$tab[3];
					}
				}
				elsif($a[0] eq "0/1" || $a[0] eq "0/2" || $a[0] eq "1/2" || $a[0] eq "0/3"|| $a[0] eq "1/3"|| $a[0] eq "2/3") {
					if($a[2]<=$hash{$i}{'mean'} && $a[2]>=$hash{$i}{'mean'}/4) {
						my @b=split(/,/, $a[1]);
						my $max=0;
						my $maxpos="";
						if(scalar(@b)==0) {
							print STDERR "Trying to split AD but get nothing! $_";
						}
						foreach (my $j=0; $j<scalar(@b); $j++) {
							if($b[$j]>$max) {
								$max=$b[$j];
								$maxpos=$j;
							}
						}
				
						if($maxpos==0) {
							$add=$tab[3];
						}
						else {
							my @c=split(/,/, $tab[4]);
							my $newpos=$maxpos-1;
							$add=$c[$newpos];
						}
					}
					$hzFlag++;
				}
				elsif($a[0] eq "1/1") {
					if($a[2]<=$hash{$i}{'mean'} && $a[2]>=$hash{$i}{'mean'}/4) {
						my @c=split(/,/, $tab[4]);
						$add=$c[0];
					}
				}
				elsif($a[0] eq "2/2") {
					if($a[2]<=$hash{$i}{'mean'} && $a[2]>=$hash{$i}{'mean'}/4) {
						my @c=split(/,/, $tab[4]);
						$add=$c[1];
					}
				}
				elsif($a[0] ne "./.") {
					print STDERR "ERROR: Found unexpected genotype ".$a[0]."\n";
				}
			}
			$outline.="\t".$add;
					 	
		}
		if($hzFlag>0) {
			print HZOUT $tab[0]."\t".$tab[1]."\t".$hzFlag."\n";
		}
		print $outline."\n";
	}
}
close(IN);
close(HZOUT);
			
