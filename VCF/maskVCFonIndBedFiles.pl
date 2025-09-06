#!/usr/bin/perl

# maskVCFOnIndBedFiles.pl  	
# written by Linnéa Smeds,                   3 May 2018
# =====================================================
# Takes a vcf file and a directory with bedfiles of 
# regions that should be masked per individual. 
#
# =====================================================
# usage perl maskVCFOnIndBedFiles.pl file.vcf dir_with_bad_regions/ diploid maskout.vcf


use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $FILTDIR = $ARGV[1];	# directory with regions to filter, named ind.bed (where ind is the same names as in the vcf header)
my $TYPE = $ARGV[2];	# haploid or diploid
my $OUT = $ARGV[3];
my $time = time;

open(OUT, ">$OUT");

# If the given type is haploid, bad sites will be changed to "." (or ./. for diploid)
my $filt;
if($TYPE eq "HAPLOID" || $TYPE eq "haploid") {
	$filt=".";
}
elsif($TYPE eq "DIPLOID" || $TYPE eq "diploid") {
	$filt="./.";
}
else{
	die "Type must be either haploid or diploid!\n";
}

# First, go through the vcf and save all positions!
my %vcfhash=();
my @vcfheader = ();
open(IN, $VCFFILE);
my $cnt=0;
while(<IN>) {
	if(/^##/){
		print OUT $_;
	}
	elsif(/CHROM/) {
		print OUT $_;
		@vcfheader=split(/\s+/, $_);
	}
	else {
		my @tab=split(/\s+/, $_);
		foreach my $a (@tab) {
			push(@{$vcfhash{$cnt}}, $a);
		};
	}
	$cnt++;	
}
close(IN);

# Then, go through each individual in the header, and read in the regions!
for(my $i=9; $i<scalar(@vcfheader); $i++) {
	my $header=$vcfheader[$i];
	print "Looking at header $header\n";
	
	my $file= $FILTDIR."/".$header.".bed";
	my %regions=();
	open(IN, $file);
	while(<IN>) {
		my @t=split(/\s+/, $_);
		for(my $j=$t[1]+1; $j<=$t[2]; $j++) {
			$regions{$t[0]}{$j}=0;
		}
	}
	close(IN);
	
	foreach my $key (keys %vcfhash) {
		my $chr=@{$vcfhash{$key}}[0];
		my $pos=@{$vcfhash{$key}}[1];
	
		if(defined $regions{$chr}{$pos}) {
			$vcfhash{$key}[$i]=$filt;
		}
	}
	
}

# And finally, print the hash!
foreach my $key (sort {$a<=>$b} keys %vcfhash) {
	print OUT join("\t", @{$vcfhash{$key}})."\n";
}

$time=time-$time;
print "Finished in $time sec.\n";
