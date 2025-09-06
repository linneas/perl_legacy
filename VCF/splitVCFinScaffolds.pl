#!/usr/bin/perl

# # # # #
# splitVCFinScaffolds.pl        
# written by Linnéa Smeds 		     31 March 2014
# ========================================================
# Splits a VCF file into several output files, one for
# each scaffold (the header is included in every file).
# The output files are called scaffoldname.some_suffix
# ========================================================
# perl splitVCFinScaffolds.pl file.vcf some_suffix

use strict;
use warnings;

my $time = time;

# Input parameters
my $VCF = $ARGV[0];
my $OUTSUFF = $ARGV[1];



# Loop over the VCF
my $header= "";
open(VCF, $VCF);
my $cnt=0;
my $last = "";
while(<VCF>) {
	if(/^#/) {
		$header.=$_;
	}			
	else {
		my @a = split(/\t/, $_);
		if($cnt==0) {
			my $out=$a[0].".".$OUTSUFF;
			open(OUT, ">$out");
			print OUT $header;
			print OUT $_;
		}
		else {
			if($last eq $a[0]) {
				print OUT $_;
			}
			else {
				close(OUT);
				my $out=$a[0].".".$OUTSUFF;
				open(OUT, ">$out");
				print OUT $header;
				print OUT $_;
			  }
		}
		$last=$a[0];
		$cnt++;
	}
}
close(OUT);
		

