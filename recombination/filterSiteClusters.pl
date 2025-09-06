#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# filterSiteClusters.pl
# written by Linnéa Smeds                        4 Sep 2015
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a file with sites and geotypes (and/or bases, phase
# etc, the number of columns is unimportant as long as the
# sequence name and position are in the first two columns)
# and check for clusters of ($SNPTHRES) SNPs closer to each
# other than ($WINDOWSIZE). 

# The output is a bed file with all filtered ranges (note 
# that the ranges can overlap, to get unique filtered
# regions use mergeBed.
# Output is printed to stdout.
# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILE = $ARGV[0];
my $WINDOWSIZE = $ARGV[1];
my $SNPTHRES = $ARGV[2];


#open(OUT, ">$OUTBED");		#Initiating outfile

# GO THROUGH THE FILE AND SAVE IN HASH
my %hash = ();
my $cnt=1;
open(IN, $FILE);
while(<IN>) {
	my @t=split(/\s+/,$_);
	my $lastcol=scalar(@t)-1;
	
#	$hash{$t[0]}{$t[1]}{'rest'}=@t[2..$lastcol];
	$hash{$t[0]}{$t[1]}{'no'}=$cnt;
#	$hash{$t[0]}{$t[1]}{'status'}="OK";
	
	$cnt++;
}
close(IN);

# AND THEN GO THROUGH IT AGAIN, LOOKING AT
# SNPTHRES POSITIONS AHEAD AND CHECK IF THEY
# LIE CLOSER THAN WINDOWSIZE BP.
open(IN, $FILE);
while(<IN>) {
	unless(/^#/) {
		my @t=split(/\s+/,$_);

		my $snps=1;
		my $check="off";
		foreach my $pos (sort {$a<=>$b} keys %{$hash{$t[0]}}) {
		
			# check position $SNPTHRES positions after our position
			if($hash{$t[0]}{$pos}{'no'}==$hash{$t[0]}{$t[1]}{'no'}+$SNPTHRES-1) {
				if($pos-$t[1]<=$WINDOWSIZE) {	#If the distans is smaller than windowsize
					my $bedstart=$t[1]-1;
					print $t[0]."\t".$bedstart."\t".$pos."\n";
				}
				last;
			}
		}
	}
}
close(IN);

