#!/usr/bin/perl

# # # # # #
# meanAndMedianCoveragePerWindow.pl
# written by Linnéa Smeds                   13 Aug 2018
# modified from meanCoveragePerWindow_repeatmasked.pl
# - I don't care about repeats and I want median as well!
# =====================================================
# Takes a coverage file (scaffold, position, coverage)
# and a window size and prints a a condensed file with
# each window on one row. 
# =====================================================
# Usage: perl meanAndMedianCoveragePerWindow.pl <cov_file> <wind_size> <out>


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameters
my $COV = $ARGV[0];
my $SCAFLIST = $ARGV[1];
my $WINDSIZE = $ARGV[2];
my $OUTPREF = $ARGV[3];

# Open outfiles
my $out1=$OUTPREF.".windstats";
open(OUT, ">$out1");
print OUT "SCAFFOLD\tSTART\tEND\tMEAN\tMEDIAN\n";

# 
my %scaffolds=();
open(IN, $SCAFLIST);
while(<IN>) {
	my @t=split(/\s+/,$_);
	$scaffolds{$t[0]}=$t[1];
	#print "DEBUG: add ".$t[0]." with value ".$t[1]."\n";
}
close(IN);


# Go through the coverage file
open(COV, $COV);
my ($totcov, $totbp) = (0, 0);
my $cnt=1;
my @arr = ();
my ($start, $end, $scaff, $len)=(1, 1, "", 0);
while(<COV>) {

	my @tab=split(/\s+/, $_);

	# First row only
	if($scaff eq "" || scalar(@arr)==0) {
		($scaff, $start) = ($tab[0], $tab[1]);
	}

	# Add the value and increase the end position
	push @arr, $tab[2];
	$end=$tab[1];


	# Time to print current window!
	if($cnt % $WINDSIZE == 0 || $cnt==$scaffolds{$scaff}) {
		my $mean = mean(@arr);
		my $median = median(@arr);

		print OUT $scaff."\t".$start."\t".$end."\t".$mean."\t".$median."\n";
#		print STDERR "DEBUG:".$scaff."\t".$start."\t".$end."\t".$mean."\t".$median."\t".scalar(@arr)."\n";
		@arr=();
		
	}
	

	
	$cnt++;

}
close(COV);
close(OUT);



# SUB TO CALCULATE MEDIAN OF ARRAY
sub median{
    my @vals = sort {$a <=> $b} @_;
    my $len = @vals;
    if($len%2) #odd?
    {
        return $vals[int($len/2)];
    }
    else #even
    {
        return ($vals[int($len/2)-1] + $vals[int($len/2)])/2;
    }
}

# SUB TO CALCULATE MEAN
sub mean {
    my @vals = @_;
    my $len = @vals;
    my $sum  = 0;
    my $result;
    foreach (@vals) { $sum += $_ }
    return $sum / $len;
}


