#!/usr/bin/perl


# # # # # #
# breakpointToTelomereDist.pl
# written by Linnéa Smeds                    Dec 2012
# ===================================================
# 
# ===================================================
# Usage: 

use strict;
use warnings;
use List::Util qw(max min);


# Input parameters
my $GRIMMBLOCK = $ARGV[0];
my $KARYOTYPE = $ARGV[1];
my $CHROM = $ARGV[2];



# Output files
my $OUTFILE = $CHROM."_telodist.txt";
open(OUT, ">$OUTFILE");

#Find chromlength from karyotype
my $chrLen = 0;
open(IN, $KARYOTYPE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if($tab[2] =~ m/N0/) {
		$chrLen+=$tab[5];
	}
}
close(IN);



# Go through the blocks and save start and stop on scaffold pos
open(IN, $GRIMMBLOCK);
my %blocks = ();
my $printflag = "off";
my $cnt = 1;
my $prevend = "";
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/,$_);

		unless($cnt==1) {

			#left edge;
			my $ldist = min($prevend+1, $chrLen-($prevend+1));

			# right edge;
			my $rdist = min($tab[6]-1, $chrLen-($tab[6]-1));

			my $dist = min($ldist, $rdist);
			my $frac = $dist/$chrLen;

			print OUT $frac."\n";
		}
		$prevend = $tab[6]+$tab[7]-1;
		$cnt++;
	}
}
close(IN);
