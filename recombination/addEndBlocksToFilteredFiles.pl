#!/usr/bin/perl

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# addEndBlocksToFilteredFiles.pl
# written by Linnéa Smeds                      17 July 2015
# ---------------------------------------------------------
# A try out-script to see what happens if one adds the first
# and last block to the filtered files (so that we don't
# miss recombination that happens closer than 1Mb to the end).

# Infile1 - filtered blocks 
# Chr1	699135		54690918	Pat	127137
# Chr1	54691498	92479538	Mat	94069
# Chr1	92506307	119997414	Pat	62414
#
# Infile2 - all blocks
# Chr1	60915	697103	Mat	365
# Chr1	699135	1316085	Pat	775
# Chr1	1318156	1318156	Mat	1
# ---------------------------------------------------------
# Example 

use strict;
use warnings;

# Input parameters
my $FILTBLOCKS = $ARGV[0];
my $ALLBLOCKS = $ARGV[1];
my $OUT = $ARGV[2];


open(OUT, ">$OUT");		#Initiating outfile

# Save the first and last line of the allblocks file
open(IN2, $ALLBLOCKS);
my $first = <IN2>;
my $last = "UNDEF";
while(<IN2>){
	if (eof) {
		$last=$_;
	}
}
close(IN2);

# Go through the filtered block file, compare the first and last
# with the saved file and print blocks and extra lines if they aren't
# overlapping.
		
open(IN, $FILTBLOCKS);

my $head = <IN>;

if($head && $head =~ m/Chr/) {
	my @a1=split(/\s+/, $head);
	my @a2=split(/\s+/, $first);
	if($a1[1]>$a2[2]) {		#First filtered block start AFTER first all-block
		print OUT $first;
		if($a1[1]-$a2[2]>10000) {
			print STDERR "$ALLBLOCKS Start: Distance between blocks is longer than 10kb!\n";
		}
	}
	print OUT $head;
}
else{
	print OUT $first;
	print "$FILTBLOCKS is empty!\n";
}

my $cnt=0;
while(<IN>) {
	$cnt++;
	if(eof) {# Last line
		my @b1=split(/\s+/, $_);
		my @b2=split(/\s+/, $last);
		print OUT $_;
		unless ($last eq "UNDEF") {
			if($b1[2]<$b2[1]) {		#Last filtered block ends BEFORE last all-block
				print OUT $last;
				if($b2[1]-$b1[2]>10000) {	
					print STDERR "$ALLBLOCKS End: Distance between blocks is longer than 10kb!\n";
				}
			}
		}
	}
	else {
		print OUT $_;
	}
}
close(IN);

# If there is none or only one line in the filt file, we still want to look at the 
# last line in the all file! 
if($cnt==0) {	# No middle or last lines in the filt file

	unless($last eq "UNDEF") {
	
		if($head !~ m/Chr/) {	# No first line either! =>Print the last line!
			print OUT $last;
		} 
		else {					# There is a first filt line, check if it's different from last in allfile
			print "$FILTBLOCKS: Only one line in file!\n";
			my @c1=split(/\s+/, $head);
			my @c2=split(/\s+/, $last);
			if($c1[2]<$c2[1]) {
				print OUT $last;
			}
		}
	}
}		
close(OUT);
