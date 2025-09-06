#!/usr/bin/perl

# # # # # #
# extractWindowsFromChromList.pl
# written by Linnéa Smeds                   19 Feb 2014
# =====================================================
# Takes the linkage file with scaffolds on chromosomes
# and a window size, and print all windows in the same
# order as they come in the linkage file.
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $LIST = $ARGV[0];
my $WINDSIZE = $ARGV[1];

# Ge through the list file
open(IN, $LIST);
while(<IN>) {
	my @line = split(/\s+/, $_);
	my $chr = $line[0];
	my $scaf = $line[1];
	my $scaflen = $line[2];

	my %windows = ();
	my $cnt=1;
	for(my $i=1; $i<$scaflen; $i+=$WINDSIZE) {
		$windows{$cnt}{'start'}=$i;
		$windows{$cnt}{'end'}=min($i+$WINDSIZE-1, $scaflen);
		$cnt++;
	}

	# Print out windows (backwards if needed)
	if($line[3] eq "-") {
		foreach my $num (sort {$b<=>$a} keys %windows) {
			print $chr."\t".$scaf."\t".$windows{$num}{'start'}."\t".$windows{$num}{'end'}."\n";
			delete $windows{$num};
		}
	}
	else {
		foreach my $num (sort {$a<=>$b} keys %windows) {
			print $chr."\t".$scaf."\t".$windows{$num}{'start'}."\t".$windows{$num}{'end'}."\n";
			delete $windows{$num};
		}
	}
	
}
close(IN);
