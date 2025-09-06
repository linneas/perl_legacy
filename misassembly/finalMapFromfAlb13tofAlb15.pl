#!/usr/bin/perl


# # # # # #
# finalMapFromfAlb13tofAlb15.pl
# written by Linnéa Smeds                  28 Sep 2012
# ====================================================
# Takes the file FicAlb1.4_onto_fAlb13.txt and the
# file FicAlb1.4_split_20120927.map (with all split
# scaffolds) and the name mapping list between fAlb15
# and FicAlb1.4 (fAlb15.reformated.map) and combines 
# them into one list, with the fAlb15 name along with
# the fAlb13 name and positions. 
# 
# fAlb15_name   fAlb13_name  fAlb13_start  fAlb13_stop
# N00021        S00024       1             10732945
#
# ====================================================


use strict;
use warnings;

# Input parameters
my $FicAlb2fAlb = $ARGV[0];
my $splitList = $ARGV[1];
my $ReformatList = $ARGV[2];
my $OUT = $ARGV[3];


# My outfile 
open(OUT, ">$OUT");
print OUT "fAlb15NAME	fAlb13NAME	STARTonfAlb13	STOPonfAlb13\n"; 

# Save all splits
my %Splits = ();
open(IN, $splitList);
while(<IN>) {
	my ($seq, $old, $start, $stop) = split(/\s+/, $_);
	$Splits{$seq}{'old'}=$old;
	$Splits{$seq}{'start'}=$start;
	$Splits{$seq}{'stop'}=$stop;
}
close(IN);

#Save the original positions
my %positions = ();
open(IN, $FicAlb2fAlb);
while(<IN>) {
	my ($orig, $start, $stop) = split(/\s+/, $_);
	$positions{$orig}{'start'} = $start;
	$positions{$orig}{'stop'} = $stop;
}
close(IN);

#Go through new scaffolds 
open(IN, $ReformatList);
while(<IN>) {
	my ($old, $new) = split(/\s+/, $_);

	my ($orig, $origstart, $origstop);
	
	#Check if sequence is split
	if(defined $Splits{$old}) {
		$orig = $Splits{$old}{'old'};
		unless(defined $positions{$orig}) {
			print "ERROR: $orig is not defined!!\n";
		}
		$origstart = $positions{$orig}{'start'}+$Splits{$old}{'start'}-1;
		$origstop = $positions{$orig}{'start'}+$Splits{$old}{'stop'}-1;
	}
	else {
		$orig = $old;
		$origstart = $positions{$orig}{'start'};
		$origstop = $positions{$orig}{'stop'};
	}

	print OUT $new."\t".$orig."\t".$origstart."\t".$origstop."\n";
}
close(IN);

