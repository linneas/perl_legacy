#!/usr/bin/perl

# # # # # #
# fragmentCoverageFromSam.pl
# written by Linnéa Smeds                   11 March 2014
# =======================================================
# Takes a sam file with only wanted (and properly paired)
# reads, and then calculates the fragment coverage by 
# looking at the left read in each pair, and add 1X to 
# each position to the start and to all following pos up
# until start+insert size. 
# =======================================================
# Usage: perl meanAndMedianCoverage_repeatMasked.pl


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $SAM = $ARGV[0];
my $OUT = $ARGV[1];

# Open outfile
open(OUT, ">$OUT");

# Save the positions in a hash
my %cov=();


# Go through the sam
open(SAM, $SAM);
my ($tot, $used) = (0,0);
while(<SAM>) {
	my @arr = split(/\s+/, $_);

	# Only looking at the left read in each pair that 
	# has their mate on the same scaffold.
	if($arr[6] eq "=" && $arr[8]>0) {
		
		for(my $i=$arr[3]; $i<$arr[3]+$arr[8]; $i++) {
			if(defined $cov{$arr[2]}{$i}) {
				$cov{$arr[2]}{$i}++;
			}
			else {
				$cov{$arr[2]}{$i}=1;
			}
		}
		$used++;
	}
	$tot++;
}
close(SAM);

foreach my $scaff (sort keys %cov) {
	foreach my $pos (sort {$a<=>$b} keys %{$cov{$scaff}}) {
		print OUT $scaff."\t".$pos."\t".$cov{$scaff}{$pos}."\n";
	}
}

# Stats for tot genome
print "$used reads used out of $tot reads in file\n";

