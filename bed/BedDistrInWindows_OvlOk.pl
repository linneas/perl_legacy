#!/usr/bin/perl


# # # # # #
# BedDistrInWindows_ovlOk.pl 
# written by Linnéa Smeds                      19 Feb 2014
# 
# ========================================================
# This scripts do the same as BedDistrInWindows.pl, but it 
# also keep track on the exaxt positions (more memory
# demanding, but neccessary if the bed regions are over-
# lapping)
# NOTE! For medium size bed files (like a complete repeat
# file for the genome) a login node on uppmax is NOT
# enough!.
# ========================================================
# Usage: perl BedDistrInWindows_ovlOk.pl <bed> <windfile> <out>
#
# Example: 

use strict;
use warnings;

# Input parameters
my $BED = $ARGV[0];	# At least three columns: sequence name, start and stop 
my $WINDOWS = $ARGV[1];	# Four columns: Chrom, scaffold, window start and window stop 
my $OUT = $ARGV[2];

my $time = time;

# To save at least some memory, we first check which scaffolds we need to save
my %wind=();
open(WIN, $WINDOWS);
while(<WIN>) {
	my @tab = split(/\s+/, $_);
	$wind{$tab[1]}=1;
}


# Save each single position covered in the bed file
# NOTE! Memory demanding for big bed files!
my %savePos = ();
open(IN, $BED);
while(<IN>) {
	unless(/^#/) {
		my @tab = split(/\s+/, $_);
		if(defined $wind{$tab[0]}) {
			for(my $i=$tab[1]; $i<=$tab[2]; $i++) {
				$savePos{$tab[0]}{$i}=1;
			}
		}
	}
}
close(IN);

open(OUT, ">$OUT");
open(WIN, $WINDOWS);
while(<WIN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	my $cnt=0;
	#print "looking at ".$tab[0]."\n";
	foreach my $key (keys %{$savePos{$tab[1]}}) {
		if($key>=$tab[2] && $key<=$tab[3]) {
	#		print "position $key lies within ".$tab[2]." and ".$tab[3]."\n";
			$cnt++;
			delete $savePos{$tab[0]}{$key};
		}
	}
	my $percent = $cnt/($tab[3]-$tab[2]+1);
	print OUT $_."\t".$percent."\n";
}

$time=time-$time;
print "Total time elapsed: $time sec\n";
