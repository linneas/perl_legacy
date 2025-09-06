#!/usr/bin/perl

# convertVCFtoFasta.pl  	
# written by Linnéa Smeds,                   16 May 2014
# =====================================================
# 
# =====================================================
# usage perl convertVCFtoFasta.pl file.vcf out.fst

use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $FASTA = $ARGV[1]; 	# Output fasta file

# Make hash to save all the sequences!
my %seqs = ();

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

		for (my $i=9; $i<scalar(@tab); $i++) {
			my $add;
			if($tab[$i] eq "." || $tab[$i] eq "./.") {
				$add="N";
			}
			else {
				my @a = split(/:/, $tab[$i]);
				my @base = split(/,/, $tab[4]);
				if($a[0] eq "0") {
					$add=$tab[3];
				}	
				elsif($a[0] eq "1") {
					$add=$base[0];
				}
				elsif($a[0] eq ".") {
					$add="N";
				}
				elsif($a[0] eq "2") {
					$add=$base[1];
					print "WARNING: ".$tab[0].":".$tab[1]." - GT is ".$a[0]."!\n";
				}				
				else{
					print "ERROR: ".$tab[0].":".$tab[1]." - GT is ".$a[0]."!\n";
				}
			}
			$seqs{$i}{'seq'}.=$add;
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


