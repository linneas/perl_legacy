#!/usr/bin/perl


# # # # # #
# sort_scaffolds_by_species.pl
# written by Linnéa Smeds		  1 June 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;


my $scafList = $ARGV[0];	#List with two columns, scaffold name and species (latin)
my $specTypeList = $ARGV[1];	#Three columns; number species (latin) and type
my $vertebrateList = $ARGV[2];	#Two columns; species and type (only vertebrates)

my %types = ();
open(IN, $specTypeList);
while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	$types{$tab[1]}=$tab[2];
}
close(IN);

my %vertes = ();
open(IN, $vertebrateList);
while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	$vertes{$tab[0]}=$tab[1];
#	print "adding ".$tab[0]." with sample ".$tab[1]."\n"; 
}
close(IN);

open(IN, $scafList);
while(<IN>) {
	chomp($_);
	my ($scaff, $sp) = split(/\t/, $_);
	
	if(defined $types{$sp}) {
		if($types{$sp} eq "Vertebrates") {
			if(defined $vertes{$sp}) {
				print $scaff."\t".$sp."\t".$vertes{$sp}."\n";
			}
			else {
				print $scaff."\t".$sp."\tUNKNOWN VERT\n";				
			}
		}
		else {
			print $scaff."\t".$sp."\t".$types{$sp}."\n";
		}
	}
	else  {
		print $scaff."\t".$sp."\tUNKNOWN OTHER\n";
	}
}
close(IN);
