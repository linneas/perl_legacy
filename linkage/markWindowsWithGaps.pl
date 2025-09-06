#!/usr/bin/perl


# # # # # #
# markWindowsWithGaps.pl
# written by Linnéa Smeds		       Mar 2012
# =====================================================
# Takes a bed file with windows and one with gaps and
# add a fourth binary column to mark if a window has a 
# gap or not. 
# =====================================================
# Usage: 
#

use strict;
use warnings;

# Input parameters
my $WINDFILE = $ARGV[0];	 
my $GAPFILE = $ARGV[1];
my $OUT = $ARGV[2];

open(OUT, ">$OUT");


# Save the gaps
my %gaps = ();
open(GAP, $GAPFILE);
while(<GAP>) {
	my @tab = split(/\t/, $_);
	$gaps{$tab[0]}{$tab[1]}=$tab[2];
}
close(GAP);

#Go through windows
open(IN, $WINDFILE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/,$_);
	my $printflag="0";
	
	foreach my $start (sort {$a<=>$b} keys %{$gaps{$tab[0]}}) {
		#Overlap
		if($start<=$tab[2] && $gaps{$tab[0]}{$start} >=$tab[1]) {
			$printflag="1";
			last;
		}
	}

	print OUT $_."\t".$printflag."\n";
}
close(IN);

