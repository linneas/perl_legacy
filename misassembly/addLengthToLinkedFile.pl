#!/usr/bin/perl


# # # # # #
# addLengthToLinkedFile.pl
# written by Linnéa Smeds		      Sept 2012
# =====================================================
# 
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $LinkList = $ARGV[0];	 
my $lengthFile = $ARGV[1];
my $outfile = $ARGV[2];	


#Save lengths
my %lengths = ();
open(IN, $lengthFile);
while(<IN>) {
	my ($scaf, $len) = split(/\s+/, $_);
	$scaf =~ s/>//;
	$lengths{$scaf}=$len;
}
close(IN);


#open output file
open(OUT, ">$outfile");


# Change length in link file
my $printFlag = "off";
open(IN, $LinkList);
while(<IN>) {
	my @tab = split(/\s+/, $_);

	if($tab[2] != $lengths{$tab[1]}) {
		print $tab[1]." has the wrong length! Changing from ".$tab[2]." to ".$lengths{$tab[1]}."!\n";
		$tab[2] = $lengths{$tab[1]};
		my $out = join("\t",@tab);
		print OUT $out."\n";
	}
	else {
		print OUT $_;
	}
}
close(IN);


	
