#!/usr/bin/perl

# # # # # #
# translateOLDtofAlb15.pl
# written by Linnéa Smeds                 October 2012
# ====================================================
# Takes a file of scaffolds and positions from for 
# example fAlb13 or FicAlb1.4 and uses the mapfile 
# fAlb15_onto_XXX.txt to find the new fAlb15 positions. 
# The scaffold name must always be in the first column
# and the columns containing positions (as many as 
# you want) are given with numbers separated with ",".
# For example to translate positions in columns 3 and 4
# use "3,4" as second input (Use "real" column numbers
# starting with 1, not indices).
# NOTE: If any of the positions falls outside of the
# new assembly, the line is skipped.
# 
# USAGE:
# perl translateOLDtofAlb15.pl <FILE TO TRANSLATE> \
#		<COLUMNS> <MAP FILE> <OUTPUT NAME>
# 
# Input example file "genes.gtf":
# S00001	exon	1	100	.	+	. gene_id "ENSTGUP00000014145_1"
# S00001	exon	200	300	.	+	. gene_id "ENSTGUP00000014145_1"
#
# Run command:
# perl translateOLDtofAlb15.pl genes.gtf "3,4" \
#		fAlb15_onto_fAlb13.txt new_genes.gtf	
# ====================================================

use strict;
use warnings;

# Input parameters
my $INFILE = $ARGV[0];
my $COLUMNS = $ARGV[1];
my $MAP = $ARGV[2];
my $OUT = $ARGV[3];

# Make hash of the map file
my %mapping = ();
open(IN, $MAP);
while(<IN>) {
	my ($new, $old, $start, $stop) = split(/\s+/, $_);
	$mapping{$old}{$start}{'new'}=$new;
	$mapping{$old}{$start}{'stop'}=$stop;
}

# Open outfile 
open(OUT, ">$OUT");


# Go through the infile, change the name and position columns
# and print the line with the new scaffold name and positions 
open(IN, $INFILE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\t+/, $_);

	my @col = split(/,/, $COLUMNS);
	my $scaff = "";
	my $printFlag = "on";
	foreach my $c (@col) {
		my $c=$c-1;	#index is real col_no-1
	#	print "kollar på Column $c\n";
			
		#New position
		my $found = "no";
		foreach my $key (sort {$a<=>$b} keys %{$mapping{$tab[0]}}) {
#			print "DEBUG: comparing ".$tab[$c]." on ".$tab[0]." with $key and ".$mapping{$tab[0]}{$key}{'stop'}."\n";
			if($key<=$tab[$c] && $mapping{$tab[0]}{$key}{'stop'}>=$tab[$c]) {
#				print "DEBUG: ".$tab[$c]." from ".$tab[0]." is found on ".$mapping{$tab[0]}{$key}{'new'}."\n";
				if($scaff ne "" && $mapping{$tab[0]}{$key}{'new'} ne $scaff) {
					print $tab[0].": positions are located on a more than one scaffold (".$mapping{$tab[0]}{$key}{'new'}.",$scaff)\n";
					$printFlag="off";
				}
				$tab[$c] = $tab[$c]-$key+1;
				$scaff = $mapping{$tab[0]}{$key}{'new'};
				$found = "yes";
				last;
			}
		}
		if($found eq "no") {
			print $tab[0].": position ".$tab[$c]." is not included in this version!\n";
			$printFlag = "off";
		}
	}

	if($printFlag eq "on") {
		$tab[0]=$scaff;
		print OUT join("\t", @tab) . "\n";
	}
	 
}
close(IN);

