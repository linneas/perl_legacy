#!/usr/bin/perl


# # # # # #
# divideVCFDirToSepWindFiles.pl
# written by Linnéa Smeds		       		    Feb 2012
# ======================================================
# Divides all VCF files in a given directory into separate
# files for each window (of a given window size). Can 
# include the VCF header in each output or not (right now
# not, because that code is commented out). The output 
# files are called: "prefix"scaffold_start-end."suffix"
# where prefix and suffix are given as input.
# ======================================================
# Usage: perl divideVCFtoSepWindFiles.pl <DIR> <WIND SIZE> \
# 									<PREFIX> <SUFFIX>
#

use strict;
use warnings;
 use List::Util qw(min max); 

# Input parameters
my $dir = $ARGV[0];	 	   
my $WindSize = $ARGV[1];
my $prefix = $ARGV[2];
my $suffix = $ARGV[3];
my $header = $ARGV[4];											###Adding header from different file

#print "checking directory $dir\n";								###Debugging

open(IN, $header);
my $shortHead = "";
while(<IN>) {
	$shortHead .= $_;
}

opendir(DIR, $dir) or die "can't opendir $dir: $!";
while (defined(my $VCFfile = readdir(DIR))) {
	
	if($VCFfile =~ m/\.vcf/) {
		my @name = split(/\./, $VCFfile);
		my $scaffold = $name[0];

#		print "looking at $scaffold\n";							###Debugging

		my $scafLen;
		#my $HEAD = "";											###For ADDING THE VCF HEADER TO EACH OUTFILE

		open(IN, $VCFfile);
		my $line = <IN>;
		while($line =~ m/^#/) {
#			$HEAD .= $line;										###For ADDING THE VCF HEADER TO EACH OUTFILE
			if($line =~ m/##contig=<ID=$scaffold/) {
				my @tab = split(/[>=<]/, $line);
				$scafLen=$tab[4];
#				print "length of $scaffold is $scafLen\n";		###Debugging
			}
			$line = <IN>;
		}

		for(my $i=1; $i<$scafLen; $i+=$WindSize) {
			my $end = min($i+$WindSize-1, $scafLen);
			my $outfile = $prefix.$scaffold."_".$i."-".$end.".".$suffix;
			open(OUT, ">$outfile");
#			print OUT $HEAD;									###For ADDING THE VCF HEADER TO EACH OUTFILE
			print OUT $shortHead;								###For adding header from a different file

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
	}
}
