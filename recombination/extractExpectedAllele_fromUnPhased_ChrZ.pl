#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# extractExpectedAllele_fromUnPhased_ChrZ.pl
# written by Linnéa Smeds                       16 July 2015
# ----------------------------------------------------------
# DESCRIPTION:
# 
# Takes a file: 
#Chr4A	27	A	G	0/1	0/0	0/1	0/0	0/1	0/1	Pat	Mat
#Chr4A	301	G	T	0/1	0/0	0/1	0/0	0/1	0/1	Mat	Pat
# Where the columns are chr, pos, ref, alt, grandfather, 
# grand-mother, parent, mother, father, child, line, block
# NOTE! Prefilter the file to keep only lines where the obs.
# line is DIFFERENT from the assigned blocks (potential NCO).
#
# Finds the expected base according to the block and the 
# observed base and print them as last columns.

# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $LINAGE = $ARGV[1];	# M or P
my $OUT = $ARGV[2];

unless($LINAGE eq "M" || $LINAGE eq "P"){
	die "Second parameter must be \"M\" or \"P\", depending on linage.\n";
}

open(OUT1, ">$OUT");		# Initiating outfile
my $OUT2=$OUT.".removed";
open(OUT2, ">$OUT2");

# GO THROUGH THE FILE
open(IN, $FILE);
while(<IN>) {

	my @t=split(/\s+/,$_);
			
	# First we need to know which of the alleles that is inherited from the parent in question
	# There are only three possible GT for the other parent ("0/0", "0/1" or "1/1", (only two 
	# if the other is female) all other cases are discarded)
	my $main="";
	my $oth="";
	my $kid=$t[9];
	my $a="";
			
	if($LINAGE eq "M") {	# Maternal line
		$main=$t[7];
		$oth=$t[8];
	}
	elsif($LINAGE eq "P") {	# Paternal line
		$main=$t[8];
		$oth=$t[7];
	}
	
	# If the kid only has one allele, it's a female, and it must be non-ParZ 
	# and the allele comes directly from the dad 
	if(length($kid)==1) {	
		$a=$kid;
	}
	# offspring is male (or we're looking at PAR)
	else{ 
		#  other parent is a female (ind is father)
		if(length($oth)==1) {
			if($oth eq "0") {
				if($kid eq "0/0") {
					$a="0";
				}
				elsif($kid="0/1") {
					$a="1";
				}
				else {
					print STDERR "Weird combination on line $_";
				}
			}
			elsif($oth eq "1") {
				if($kid eq "0/1") {
					$a="0";
					}
				elsif($kid="1/1") {
					$a="1";
				}
				else {
					print STDERR "Weird GT in other parent on line $_";
				}
			 }
		}
		# Other parent has two alleles (male or we're in PAR)
		else {	
			if($oth eq "0/0") {	#If other p is "0/0", the offspring can be either "0/0" or "0/1"
				if($kid eq "0/1") {
					$a=1;
				}
				elsif($kid eq "0/0") {
					$a=0;
				}
				else {
					print STDERR "Weird combination on line $_";
				}
			}
			elsif($oth eq "0/1") {	# If other p is "0/1", the offspring can be either "0/0" or "1/1"
				if($kid eq "0/0") {
					$a=0;
				}
				elsif($kid eq "1/1") {
					$a=1;
				}
				else {
					print STDERR "Weird combination on line $_";
				}
			}
			elsif($oth eq "1/1") {	# If other p is "1/1", the offspring can be either "0/1" or "1/1"
				if($kid eq "0/1") {
					$a=0;
				}
				elsif($kid eq "1/1") {
					$a=1;
				}
				else {
					print STDERR "Weird combination on line $_";
				}
			}
		}
	 }
				
	# Now we know which allele that came from the parent in question!
	# That is the observed allele, which means the expected allele must
	# be the other one. 
	
	my $obs="";
	my $exp="";
	
	if($a==0){
		$obs=$t[2];
		$exp=$t[3];
	}
	elsif($a==1){
		$obs=$t[3];
		$exp=$t[2];
	} 
	else {
		print STDERR "Something is wrong, allele is neither 0 or 1!\n";
	}
	
	# Add the obs and exp to the end!
	print OUT1 join("\t", @t)."\t".$obs."\t".$exp."\n";

}
close(IN);
close(OUT1);
close(OUT2);

