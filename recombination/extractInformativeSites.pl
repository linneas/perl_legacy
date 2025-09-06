#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# extractInformativeSites.pl
# written by Linnéa Smeds                        7 May 2015
# Bugfixed 30 June 2015, didn't compare the parent haplotype
# between the two trios properly for the paternal line. 
# ----------------------------------------------------------
# DESCRIPTION:
# 
# Takes a file: 
#Chr4A   27      0/1     0/1     0/1     0/1     0/1     0/1
#Chr4A   30      0|0     0|0     0|0     0|0     0|0     0|0
#Chr4A   31      ./.     ./.     0|0     0|0     ./.     ./.
#Chr4A   55   	 1|0     0|0     0|1     1|0     0|0     1|0
# Where the columns are grandfather, grandmother, parent, 
# mother, father, child.
#
# Extracts positions where the allele in the child can be 
# traced back to one of the grandparents (for the linage in
# question, given as "M"=maternal or "P"=paternal.
# Valid positions would be if the grandparents are different
# from eachother, the parent is "0|1" or "1|0" (and similar
# to mother or father column, whichever it is), and the other 
# parent and offspring is NOT both "0|1" (or "1|0" or "0/1").
# Hence, it's not possible to have "0/1" in all three indi-
# viduals in a trio.


# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $LINAGE = $ARGV[1];	#M or P

unless($LINAGE eq "M" || $LINAGE eq "P"){
	die "Second parameter must be \"M\" or \"P\", depending on linage.\n";
}


#open(OUT, ">$OUT");		#Initiating outfile


# GO THROUGH THE FILE
open(IN, $FILE);
while(<IN>) {
	unless(/.\/./) {		# If there is a single "/", (0/1 or ./.) we don't want the line!
		
		# Now there shouldn't be any lines left were the second parent and the offspring 
		# both are heterozygous, because they can be phased and should therefore include a "/"

		my @t=split(/\s+/,$_);
	
		if($t[2] ne $t[3] && ($t[4] eq "0|1" || $t[4] eq "1|0")) {	# First trio is ok
			my $type="UNKNOWN";
			my $printflag="off";
			my $lin="";
			my ($m, $p)=split(/\|/, $t[7]);
			if($LINAGE eq "M" && ($t[4] eq $t[5] || $t[4] eq reverse($t[5]))) {	#Maternal line, have the same haplotype in both trios
				$printflag="on";
				$lin=$m;				
			}
			elsif($LINAGE eq "P" && ($t[4] eq $t[6] || $t[4] eq reverse($t[6]))) {	#Paternal line, have the same haplotype in both trios #BUGFIXED!
				$printflag="on";
				$lin=$p;
#				print "DEBUG: we have found the paternal line, and will look at $lin\n";
	
			}
			
			#Only print rows that are approved (first check state)
			if($printflag eq "on") {
				my ($g1, $g2)=($t[2], $t[3]);
				if($lin =~ m/$g1/) {	#Matches first grandparent
					if($lin =~ m/$g2/) {	#Also matches second grandparent
						#If it matches both, it must come from the grandparent that ONLY contains this allele
						if("$lin|$lin" eq $g1) {
							 $type="Pat";
						}
						elsif("$lin|$lin" eq $g2){
							$type="Mat";
						}
						else {
							print "ERROR: $lin|$lin is matching neither $g1 nor $g2!!\n";
						}
					}
					else {	# Only matches the first grandparent
						$type="Pat";
					}
				}
				else { # only matches the second grandparent
					$type="Mat";
				}
				
				print join("\t", @t)."\t".$type."\n";
			}
			
		}
	}
}
close(IN);
	

