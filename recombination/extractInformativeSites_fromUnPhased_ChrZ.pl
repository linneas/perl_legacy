#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# extractInformativeSites_ChrZ.pl
# written by Linnéa Smeds                        7 May 2015
# Modified to handle ChrZ where the female individuals have
# a single chromosome. 
# ----------------------------------------------------------
# DESCRIPTION:
# 
# Takes a file: 
#ChrZ   27      0/1     0     0/1     1     0/1     0/1
#ChrZ   30      0/0     1     0/0     1     0/0     0/0
#ChrZ   31      ./.     1     0/0     0     ./.     ./.
#ChrZ   55   	1/0     0     0/1     1     0/0     1/0
# Where the columns are grandfather, grandmother, parent, 
# mother, father, child. (For chromosome Z the parent is
# always the father!)
#
# Extracts positions where the allele in the child can be 
# traced back to one of the grandparents (for the linage in
# question, given as "M"=maternal or "P"=paternal.)
# Valid positions would be if the grandparents are different
# from eachother, the parent is "0/1" (and similar to mother
# or father column, whichever it is), and the other parent
# and offspring is NOT both "0/1".
# Hence, it's not possible to have "0/1" in all three indi-
# viduals in a trio.


# ---------------------------------------------------------
# Example 

use strict;
use warnings;

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
#my $LINAGE = $ARGV[1];	# M or P <=ONLY P line IS CONSIDERED ON CHRZ (M line doesn't recombine)
my $OUT = $ARGV[1];

open(OUT1, ">$OUT");		# Initiating outfiles
my $OUT2=$OUT.".removed";
open(OUT2, ">$OUT2");

# GO THROUGH THE FILE
open(IN, $FILE);
while(<IN>) {
	unless(/\.\/\./) {		# Should already have removed "./." before, but if not...
		
		my @t=split(/\s+/,$_);
			
		if($t[2] ne $t[3] && $t[4] eq "0/1") {	# First trio is ok
			my $type="UNKNOWN";
			my $printflag="off";
			my $a="";	
			
			# First we need to know which of the alleles that is inherited from the father
			# There are only two possible GT for the mother ("0" or "1") all other cases 
			# are discarded
			my $main="";
			my $oth="";
			my $kid=$t[7];
			
			if($t[4] eq $t[6]) {	# Paternal line, must have the same haplotype in both trios 
				$main=$t[6];
				$oth=$t[5];
			}
			else {
				print STDERR "ERROR: PARENT DOESEN'T MATCH BETWEEN TRIOS: $_";
				print OUT2 $_;
				next;
			}
			
			# The offspring can be either a female (easy - only one chromosome!) or male
			if(length($kid)==1) {	
				#Offspring is a female! The allele must come from the dad.
				$a=$kid;
			}
			else {
				#offspring is a male	
				if($oth eq "0") {	#If mother is "0", the offspring can be either "0/0" or "0/1"
					if($kid eq "0/1") {
						$a=1;
					}
					elsif($kid eq "0/0") {
						$a=0;
					}
					else {
						print STDERR "ILLEGAL COMBO2: $_";
						print OUT2 $_;
						next;
					}
				}
				elsif($oth eq "1") {	# If mother is "1", the offspring can be either "0/1" or "1/1"
					if($kid eq "0/1") {
						$a=0;
					}
					elsif($kid eq "1/1") {
						$a=1;
					}
					else {
						print STDERR "ILLEGAL COMBO2: $_";
						print OUT2 $_;
						next;
					}
				}
				else {
					print STDERR "ILLEGAL GT: $_";
					print OUT2 $_;
					next;
				}
			}
			
			# Now we know which allele that came from the father!
			# Then we need to find out from which grandparent it came.
			# Also here we need to go through all possible cases and discard
			# lines interferring with inheritence
			my $gf=$t[2];
			my $gm=$t[3];
			
			if($gf eq "0/0") {
				if($gm eq "1") {
					if($a==1) {
						$type="Mat";
					}
					elsif($a==0) {
						$type="Pat";
					}
					else {
						print "ERROR! A IS NEITHER 1 NOR 0!!!\n";
					}
				}
				else {
					print STDERR "ILLEGAL COMBO1: $_";
					print OUT2 $_;
					next;
				}
			}
			elsif($gf eq "0/1") {
				if($gm eq "0") {
					if($a==1) {
						$type="Pat";
					}
					else{
						$type="Mat";
					}
				}
				elsif($gm eq "1") {
					if($a==1) {
						$type="Mat";
					}
					else{
						$type="Pat";
					}
				}
				else{				
					print STDERR "ILLEGAL COMBO1: $_";
					print OUT2 $_;	
					next;
				}		
			}	
			elsif($gf eq "1/1") {
				if($gm eq "0") {
					if($a==1) {
						$type="Pat";
					}
					else{
						$type="Mat";
					}
				}
				else {				
					print STDERR "ILLEGAL COMBO1: $_";
					print OUT2 $_;	
					next;
				}			
			}	
			else{	
				print STDERR "ILLEGAL GT: $_";
				print OUT2 $_;
				next;
			}
			
			
			# If we use a file that already contains blocks from the diploid calling,
			# we can check if they are the same or if they have changed!
			if($t[8]) {
				if($t[8] ne $type){
					print STDERR "NOTE! New block $type is not matching line $_";
				}
			}
			print OUT1 join("\t", @t[0..7])."\t".$type."\n";
		}
	}
}
close(IN);
close(OUT1);
close(OUT2);

