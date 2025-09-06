#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# extractInformativeSites_fromUnPhased.pl
# written by Linnéa Smeds                        7 July 2015
# Re-written from extractInformativeSites.pl to handle files
# that are not phased (0/1), but rather just have normal GT
# (0/0, 0/1 or 1/1). Question: what happens with other GT, like 0/2??
# ----------------------------------------------------------
# DESCRIPTION:
# 
# Takes a file: 
#Chr4A   27      0/1     0/1     0/1     0/1     0/1     0/1
#Chr4A   30      0/0     0/0     0/0     0/0     0/0     0/0
#Chr4A   31      ./.     ./.     0/0     0/0     ./.     ./.
#Chr4A   55   	 1/0     0/0     0/1     1/0     0/0     1|0
# Where the columns are grandfather, grandmother, parent, 
# mother, father, child.
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
	unless(/\.\/\./) {		# Should already have removed "./." before, but if not...
		
	
		my @t=split(/\s+/,$_);
		
		unless($t[5] eq $t[6] && $t[5] eq $t[7]) {	# (the individual trio are uninformative if they all have the same GT)
	
			if($t[2] ne $t[3] && $t[4] eq "0/1") {	# First trio is ok
				my $type="UNKNOWN";
				my $printflag="off";
				my $a="";	
				
				# First we need to know which of the alleles that is inherited from the parent in question
				# There are only three possible GT for the other parent ("0/0", "0/1" or "1/1") all other cases 
				# are discarded
				my $main="";
				my $oth="";
				my $kid=$t[7];
				
				if($LINAGE eq "M" && $t[4] eq $t[5]) {	# Maternal line, must have the same haplotype in both trios
					$main=$t[5];
					$oth=$t[6];
				}
				elsif($LINAGE eq "P" && $t[4] eq $t[6]) {	# Paternal line, must have the same haplotype in both trios 
					$main=$t[6];
					$oth=$t[5];
				}
				else {
					print STDERR "ERROR: PARENT DON'T MATCH BETWEEN TRIOS: $_";
					print OUT2 $_;
					next;
				}
				
				# Now go through all possible cases!
				if($oth eq "0/0") {	#If other p is "0/0", the offspring can be either "0/0" or "0/1"
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
				elsif($oth eq "0/1") {	# If other p is "0/1", the offspring can be either "0/0" or "1/1"
					if($kid eq "0/0") {
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
				elsif($oth eq "1/1") {	# If other p is "1/1", the offspring can be either "0/1" or "1/1"
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
				
				
				# Now we know which allele that came from the parent in question!
				# Then we need to find out from which grandparent it came.
				# Also here we need to go through all possible cases and discard
				# lines interferring with inheritence
				my $gf=$t[2];
				my $gm=$t[3];
				
				if($gf eq "0/0") {
					if($gm eq "0/1" || $gm eq "1/1") {
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
					if($gm eq "0/0") {
						if($a==1) {
							$type="Pat";
						}
						else{
							$type="Mat";
						}
					}
					elsif($gm eq "1/1") {
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
					if($gm eq "0/0" || $gm eq "0/1") {
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
				
				
				# We shouldn't come here unless everything is ok, so now we only have to print!
				print OUT1 join("\t", @t)."\t".$type."\n";
			}
		}
	}
}
close(IN);
close(OUT1);
close(OUT2);

