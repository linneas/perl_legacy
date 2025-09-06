#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $string = $ARGV[0];


my @cigars = split(/(\d+\w)/, $string);
my $maplen = 0;

#			print "cigars is @cigars\tlength of cigar is ".scalar(@cigars)."\n";

for (my $i=0; $i<scalar(@cigars); $i++) {
	if($cigars[$i] =~ m/(\d+)M/ || $cigars[$i] =~ m/(\d+)D/ ) {
		$maplen+=$1;

	}
}
print "maplen is $maplen\n";
