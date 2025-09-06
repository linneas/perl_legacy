#!/usr/bin/perl


# # # # # #
# addingVertebrateType.pl
# written by Linnéa Smeds		  19 April 2011
# =====================================================
# Takes a list with the latin name of the species and
# the number of occurances (but in the other order) and
# a list with latin names and the class they belong too
# and prints a concatenated list.
# =====================================================


use strict;
use warnings;

#Input parameters
my $list = $ARGV[0];		#Two columns; number and latin name
my $typeList = $ARGV[1];	#A list with Sp names and the type they belong to

my %types=();	
open(IN, $typeList);
while(<IN>) {
	chomp($_);
	my @t = split(/\t/, $_);
	$types{$t[0]}=$t[1];
}
close(IN);

open(IN, $list);
while(<IN>) {
	chomp($_);
	my ($no, $sp) = split(/\t/, $_);
	my $type;
	if(defined $types{$sp}) {
		$type = $types{$sp};
	}
	else {
		$type = "unknown";
	}
	
	print $no."\t".$sp."\t".$type."\n";
}
close(IN);
