#!/usr/bin/perl


# # # # # #
# get_multiple_linkage_info.pl
# written by Linnéa Smeds		      Sept 2011
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
my $scafflist = $ARGV[0];	        #Lastz output
my $LinkageInfo = $ARGV[1];	    #list with all chromosomes in the lastz file
my $FalGgaMap = $ARGV[2];          #output prefix


#Save all chromosomes in an array
my %FalGga=();
open(IN, $FalGgaMap);
while(<IN>) {
	my ($Fal, $Gga) = split(/\s+/, $_);
	$FalGga{$Fal}=$Gga;
}
close(IN);

open(IN,$scafflist);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $scaffold=$tab[2];
	unless($scaffold eq "-") {
		my @groups;
		my @markers;
		my @numbers;
		my @RefNum;
		my $lastgroup = "";
		open(LINK, $LinkageInfo);
		while(my $link = <LINK>) {
			my ($group, $marker, $pos, $scaff) = split(/\s+/, $link);
			unless($group eq $lastgroup){
				if($scaffold eq $scaff) {
					push(@groups, $group);
					push(@markers, $marker);
					$group =~ m/(Fal|chr)(\w+)/;
					push(@numbers, $2);
					push(@RefNum, $FalGga{$2});
					$lastgroup = $group;
				}
			}
		}
		close(LINK);
		print $scaffold."\t"; 
		print join(",", @groups)."\t";
		print join(",",@markers)."\t";
		print join("-", @numbers).": Gga ";
		print join("-",@RefNum)."\n";
	}
}
close(IN);




















