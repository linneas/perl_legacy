#!/usr/bin/perl

# convertVCFtoGTtable.pl  	
# written by Linnéa Smeds,                   16 May 2014
# =====================================================
# 
# =====================================================
# usage perl convertVCFtoGTtable.pl file.vcf indcov.txt 7


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];		#The vcf file with all positions
my $HZREPORT = $ARGV[1]; 	#A file where all positions with at least one heterozygot ind are saved

open(HZOUT, ">$HZREPORT");

#my $MEANCOV = $ARGV[1];	# Three columns:ind name, mean coverage and column number

#my $MININD= $ARGV[2];	# At least this many individuals needs to be covered

# Save the individual covearges in a hash
#my %hash = ();
#open(IN, $MEANCOV);
#while(<IN>) {
#	my @tab=split(/\s+/, $_);
#	$hash{$tab[0]}{'mean'}=$tab[1];
#	$hash{$tab[0]}{'col'}=$tab[2]-1;
#}
#close(IN);

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
			if($a[0] eq "0/0") {
				$add=$tab[3];
			}
			elsif($a[0] eq "0/1" || $a[0] eq "1/2" || $a[0] eq "0/2") {
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
				$hzFlag++;
			}
			elsif($a[0] eq "1/1") {
				my @c=split(/,/, $tab[4]);
				$add=$c[0];
			}
			elsif($a[0] eq "2/2") {
				my @c=split(/,/, $tab[4]);
				$add=$c[1];
			}
			elsif($a[0] ne "./.") {
				print STDERR "ERROR: Found unexpected genotype ".$a[0]."\n";
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
			
