#!/usr/bin/perl


# # # # # #
# makeBedFileWithGaps.pl
# written by Linnéa Smeds		       Mar 2012
# =====================================================
#
# =====================================================
# Usage: 
#

use strict;
use warnings;

# Input parameters
my $LIST = $ARGV[0];	 
my $GAPSIZE = $ARGV[1];
my $OUTPREF = $ARGV[2];

# Other parameters
my $label = "5kb_gap";

my $outGaps = $OUTPREF.".gap.annotation.bed"; 
my $outScafs = $OUTPREF.".scaffold.annotation.bed"; 
open(OUTG, ">$outGaps");
open(OUTS, ">$outScafs");

# Save the desired parts in a hash table with sequence
# name and direction of scaffold (+ or minus)
open(IN, $LIST);
my $cnt=0;
my $prevchr = "";
my $prevEnd = 0;
while(<IN>) {
	my @tab = split(/\s+/,$_);
	if($cnt>0) { 
		if($tab[0] eq $prevchr) {
			my $gapstart = $prevEnd+1;
			my $gapEnd = $prevEnd+$GAPSIZE;
			$prevEnd = $prevEnd+$GAPSIZE;
			print OUTG $tab[0]."\t".$gapstart."\t".$gapEnd."\t".$label."\n";
		}
		else {
			$prevEnd=0;
		}
	}
	my $scafSt = $prevEnd+1;
	$prevchr=$tab[0];
	$prevEnd=$prevEnd+$tab[2];
	print OUTS $tab[0]."\t".$scafSt."\t".$prevEnd."\t".$tab[1]." ".$tab[2]."bp\n";
	$cnt++;
}
close(IN);
close(OUTG);
close(OUTS);

