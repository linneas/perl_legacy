#!/usr/bin/perl


# # # # # #
# histogramFromTaxonlist.pl
# written by Linnéa Smeds		  19 April 2011
# =====================================================
# Takes a list as following:
#
# 1		Bacteria
# 10	Bacteria
# 53	Bacteria
# 2		Rodents
# 14	Vertebrates
# 2		Vertebrates
#
# (Made with cut -f1,3 file |sort -k2 on a species and
# class list) and merge the results by adding all 
# numbers from the same class. Print a histogram with 
# the class and the total number of occurances.
# =====================================================


use strict;
use warnings;

#Input parameters
my $list = $ARGV[0];

my $currNo = 0;
my $currType = "";
my $cnt=0;

open(IN, $list);
while(<IN>) {
	my ($no, $type) = split(/\s+/, $_);

	if($type eq "" || $type eq "UNKNOWN") {
			$type = "Unknown";
	}
	
	if($cnt==0) {
		$currType =$type;
		$currNo=$no;
	}
	else {
		if($type eq $currType) {
			$currNo+=$no;
		}
		else {
			print $currType."\t".$currNo."\n";
			$currType = $type;
			$currNo=$no;
		}
	}
	$cnt++;
}
print $currType."\t".$currNo."\n";
