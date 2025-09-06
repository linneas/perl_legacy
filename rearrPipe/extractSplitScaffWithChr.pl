#!/usr/bin/perl


# # # # # #
# extractSplitScaffWithChr.pl
# written by Linnéa Smeds                   2 July 2012
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $SPLITINFO = $ARGV[0];	#SplittingInfo file from assignScaffolds2Chrom output
my $OUT = $ARGV[1];

open(OUT, ">$OUT");

#Open file and go through scaffolds
open(IN, $SPLITINFO);
while(<IN>) {
	if (/^S0/) {
		my $scaff = $_;
		chomp($scaff);
		
		my ($topHitName, $topHit, $secBestName, $secBest) = ("",0,"",0);


		my $next = <IN>;
		while ($next =~ m/\tchr/) {
			my @t = split(/\s+/, $next);
			unless($next =~ /chrUn/) {
				if($t[2]>$topHit) {
					$secBestName=$topHitName;
					$secBest=$topHit;
					$topHitName=$t[1];
					$topHit=$t[2];
				}
				else {
					if($t[2]>$secBest) {
						$secBestName=$t[1];
						$secBest=$t[2];
					}
				}
			}			
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);

		print OUT $scaff."\t".$topHitName."\t".$secBestName."\n";

	}
}
close(OUT);
close(IN);
