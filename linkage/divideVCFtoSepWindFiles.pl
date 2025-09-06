#!/usr/bin/perl


# # # # # #
# divideVCFtoSepWindFiles.pl
# written by Linnéa Smeds		       		    Feb 2012
# ======================================================
# Divides a VCF file into windows (of a given size) for 
# a certain scaffold. Can include the VCF header in each
# output or not (right now not, because that code is 
# commented out). The output files are called:
# "prefix"wstart-wend"suffix" where prefix and suffix
# are given as input.
# Later, the script will be modified to run for all 
# scaffolds in a directory at once.
# ======================================================
# Usage: perl divideVCFtoSepWindFiles.pl <VCF> <SCAF> \
# 					<WINDOW SIZE> <PREFIX> <SUFFIX>
#

use strict;
use warnings;
 use List::Util qw(min max); 

# Input parameters
my $VCFFile = $ARGV[0];	 	   
my $Scaffold = $ARGV[1];
my $WindSize = $ARGV[2];
my $prefix = $ARGV[3];
my $suffix = $ARGV[4];


my $scafLen;
#my $HEAD = "";											###For ADDING THE VCF HEADER TO EACH OUTFILE

open(IN, $VCFFile);
my $line = <IN>;
while($line =~ m/^#/) {
#	$HEAD .= $line;										###For ADDING THE VCF HEADER TO EACH OUTFILE
	if($line =~ m/##contig=<ID=$Scaffold/) {
		my @tab = split(/[>=<]/, $line);
		$scafLen=$tab[4];
	}
	$line = <IN>;
}

for(my $i=1; $i<$scafLen; $i+=$WindSize) {
	my $end = min($i+$WindSize-1, $scafLen);
	my $outfile = $prefix.$i."-".$end.$suffix;
	open(OUT, ">$outfile");
#	print OUT $HEAD;									###For ADDING THE VCF HEADER TO EACH OUTFILE
	
	my @tab = split(/\s+/,$line);
	while($tab[1]<=$end) {
		print OUT $line;
		if(eof(IN)) {
			last;
		}	
		$line = <IN>;
		@tab = split(/\s+/, $line);
	} 
	close(OUT);
}

