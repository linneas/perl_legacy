#!/usr/bin/perl


# # # # # #
# telomeresInScaffoldEnds.pl
# written by Linnéa Smeds		     March 2012
# =====================================================
# 
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $summaryFile = $ARGV[0];	 
my $lengthFile = $ARGV[1];
my $EndLinkageFile = $ARGV[2];
my $AllLinkageFile = $ARGV[3];
my $outfile = $ARGV[4];	


# Save only scaffolds that are in the summary
my $scaffolds = "tempScaf";
system("cut -f1 $summaryFile |uniq > $scaffolds");

my %scaffolds;
open(IN, $scaffolds);
while(<IN>) {
	chomp($_);
	$scaffolds{$_}{'len'}=1000000000;
}
close(IN);
system("rm $scaffolds"); 

# Save all lengths
open(IN, $lengthFile);
while(<IN>){
	my @tabs = split(/\s+/, $_);
	if(defined $scaffolds{$tabs[0]}) {
		$scaffolds{$tabs[0]}{'len'}=$tabs[1];
	}
}
close(IN);

# Save potential End data
open(IN, $EndLinkageFile);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	if(defined $scaffolds{$tabs[1]}) {
		$scaffolds{$tabs[1]}{'chr'}=$tabs[0];
		$scaffolds{$tabs[1]}{'pos'}=$tabs[6];
		$scaffolds{$tabs[1]}{'dir'}=$tabs[3];
	}
}
close(IN);

my %linkage=();
open(IN, $AllLinkageFile);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	$linkage{$tabs[1]}=1;
}
close(IN);


# Go through the summaryfile 
open(IN, $summaryFile);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	my $distToEnd = min($tabs[1], $scaffolds{$tabs[0]}{'len'}-$tabs[2]);
	my $side = "";
	if($distToEnd==$tabs[1]) {
		$side = "start";
	}
	else {
		$side = "end";
	}

#	print "distance to closed end for ".$tabs[0]." with start ".$tabs[1]." is $distToEnd\n";
	my $flag = "";

	if(defined $scaffolds{$tabs[0]}{'chr'}) {
		if($distToEnd<20000) {
			if($scaffolds{$tabs[0]}{'pos'} eq "start") {
				if($scaffolds{$tabs[0]}{'dir'} eq "+") {
					if($side eq "start") {
						$flag = "ok";
					} 
					else {
						$flag = "no";
					}
				}
				else {
					if($side eq "end") {
						$flag = "ok";
					} 
					else {
						$flag = "no";
					}
				}
			}
			else {
				if($scaffolds{$tabs[0]}{'dir'} eq "-") {
					if($side eq "start") {
						$flag = "ok";
					} 
					else {
						$flag = "no";
					}
				}
				else {
					if($side eq "end") {
						$flag = "ok";
					} 
					else {
						$flag = "no";
					}
				}
			}
			if($flag eq "ok") {
				print "LOOKS GOOD: ".$tabs[0]." is an end scaffold and has a telomere close to its end\n";
			}
			else {
				print "WARNING: ".$tabs[0]." is an end scaffold but has the telomere close to the wrong end\n";
			}
		}
	}
	else {
		if($distToEnd<20000 && defined $linkage{$tabs[0]}) {
			print $tabs[0]." has telomeric sequence close to an end but is not an end scaffold!\n";
		}
	}
		
}
















