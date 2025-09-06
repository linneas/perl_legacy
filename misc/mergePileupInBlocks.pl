#!/usr/bin/perl

# # # # # #
# mergePilupInBlocks.pl
# written by Linnéa Smeds                     March 2012
# =====================================================
# 
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $pileup = $ARGV[0];
my $output = $ARGV[1];

open(OUT, ">$output");

#Open pileup file
open(IN, $pileup);
while(<IN>) {

	my ($scaff, $pos, $base, $cov) = split(/\s+/, $_);

	my ($start, $end, $totCov, $posCnt) = ($pos,$pos,$cov,1);
	
	my $next = <IN>;
	my ($nextScaf, $nextPos, $nextBase, $nextCov) = split(/\s+/, $next);
#	print "comparing $scaff with $nextScaf and $pos with $nextPos\n";
	while($scaff eq $nextScaf && $nextPos==$pos+1) {
		$end = $nextPos;
		$totCov+=$nextCov;
		$posCnt++;
		if(eof(IN)) {
			last;
		}	
		$next = <IN>;
		($scaff, $pos, $base, $cov) = ($nextScaf, $nextPos, $nextBase, $nextCov);
		($nextScaf, $nextPos, $nextBase, $nextCov) = split(/\s+/, $next);
	}
	seek(IN, -length($next), 1);

	my $meanCov = "NA";
	if($posCnt == 0) {
		print "Something is wrong! $scaff $start-$end has no positionCount\n";
	}
	else {
		$meanCov = int($totCov/$posCnt+0.5);
	}
	unless(eof(IN)) {
		print OUT $scaff."\t".$start."\t".$end."\t".$meanCov."\n";
	}
}

