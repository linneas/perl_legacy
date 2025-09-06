#!/usr/bin/perl

# # # # # #
# concatFromAnchors.pl		
# written by Linnéa Smeds		      						18 April 2011
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of chromosomes, and a prefix and suffix for
# the lastz files (one for each chromosome).

use strict;
use warnings;


# Input parameters
my $chrList = $ARGV[0];
my $catscafLenFile = $ARGV[4];
my $chrLenFile = $ARGV[5];

my $steps;

# GO THROUGH ALL CHROMOSOMES ONE BY ONE
# AND RUN THE DIFFERENT STEP
open(IN, $chrList);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);
	
	my $segmentFile = "cat".$chrom.".segments";
	
	# PAINT CHROMOSOMES
	my $scale = 4;
	my $chrNo = $chrom;
	if($chrNo =~ m/chr\d+/) {
		$chrNo =~ s/[a-zA-z]//g;	
		print "looking at chromosome $chrNo\n";
		if($chrNo < 10) {
			$scale = 4;
		}
		else {
			$scale = 16;
		}
	}
	elsif($chrNo =~ m/chrZ/ || $chrNo =~ m/chrUn/) {
		$scale = 4;
	}
	else {
		$scale = 16;
	}

	system("perl /bubo/home/h14/linnea/private/scripts/draw_chrom_color.pl $segmentFile $chrom $scale $catscafLenFile $chrLenFile");	
}






