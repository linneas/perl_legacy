#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# compareDiploidCallsWithHaploid.pl
# written by Linnéa Smeds                      15 Sept 2015
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a file with informative sites and (diploid) GT, and
# a file with vcf file names and which columns (1-based)  
# they correspond to. Then go through each of these columns 
# and correct the GT with the haploid call. 

# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $SITEFILE = $ARGV[0];
my $VCFLIST = $ARGV[1];
my $OUT = $ARGV[2];

# The site file should not be very long so we can go through
# it twice, first to check which positions to save and then
# to check the GTs.
my %pos = ();
open(IN, $SITEFILE);
while(<IN>) {
 my @t=split(/\s+/, $_);
 $pos{$t[0]}{$t[1]}="temp";	#Just give them some value to define the position!
}
close(IN);

# Go through the list with vcf files and open each of them 
open(LST, $VCFLIST);
my @column=();
while(<LST>) {
	my ($file, $col)=split(/\s+/, $_);
	$col=$col-1;	#Change to 0-based pos
	push @column, $col;
	open(VCF, $file);
	while(my $line=<VCF>) {
		unless($line =~m/^#/) {
			my @t=split(/\s+/,$line);
			if(defined $pos{$t[0]}{$t[1]}) {
				if($pos{$t[0]}{$t[1]} eq "temp") {
					delete $pos{$t[0]}{$t[1]};	# Delete the key to get rid of the temp val
				}
				my @a=split(/:/, $t[9]);
				if($a[0]==0) {
					$pos{$t[0]}{$t[1]}{$col}="0";
				}
				elsif($a[0]==1) {
					$pos{$t[0]}{$t[1]}{$col}="1";
				}
				else {
					$pos{$t[0]}{$t[1]}{$col}="REMOVE";
					print "ERROR! Weird GT ".$a[0]." at ".$t[0]." ".$t[1]." in column $col\n"; 
					print $line;
				}
			}	
		}
	}
	close(VCF);
}
close(LST);

open(OUT, ">$OUT");
# Go through the sites file once more, comparing GT
open(IN, $SITEFILE);
while(<IN>) {
	my @t=split(/\s+/, $_);
	# First check if this pos is still assigned "temp" (meaning there was
	# no entry for this position in the vcf. But since we've previously 
	# checked that all incomming positions are ok, this only means all ind
	# are homozygous for the reference.
	if($pos{$t[0]}{$t[1]} eq "temp") {	
		delete $pos{$t[0]}{$t[1]};
		foreach my $c (@column) {
			 $pos{$t[0]}{$t[1]}{$c}="0";
		}
	}
	my $printflag="on";	#Set a printflag which controls the output
		
	# Now, go through all columns and compare and change the val
	foreach my $c (@column) {
		unless(defined $pos{$t[0]}{$t[1]}{$c}) {	#the above for loop only catch positions where non of the columns are defined
			$pos{$t[0]}{$t[1]}{$c}=0;
		}
	
	 	if($t[$c] ne $pos{$t[0]}{$t[1]}{$c}."/".$pos{$t[0]}{$t[1]}{$c}) {
	 		print STDERR "MISMATCH! $c has haploid GT ".$pos{$t[0]}{$t[1]}{$c}." on line $_";
	 	}
	 	if($pos{$t[0]}{$t[1]}{$c} eq "REMOVE") {
	 		$printflag="off";
	 		
	 	}
		$t[$c]=$pos{$t[0]}{$t[1]}{$c};	 	
	}
	if($printflag eq "on") {
		print OUT join("\t", @t)."\n";
	}	
}
close(IN);
close(OUT);
