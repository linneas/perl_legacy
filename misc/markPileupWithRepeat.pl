#!/usr/bin/perl

# # # # # #
# markPilupWithrepeat.pl
# written by Linnéa Smeds                       Feb 2012
# ======================================================
# Take a pileup file (with all columns or reduced, first
# four columns needed) and adds a R as a last column if
# the base is masked as a repeat in the annotation file
# (at least
# ======================================================
# Usage: perl 
#
# Example: perl 


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $pileup = $ARGV[0];
my $repeatFile = $ARGV[1];
my $output = $ARGV[2];

open(IN, $repeatFile);
open(PIL, $pileup);
open(OUT, ">$output");
while(<IN>) {

	my @tab = split(/\s+/, $_);
	my $pile = <PIL>;
#	chomp($pile);
#	print "nu är pile $pile\n";
	my @piletab = split(/\t/, $pile);

#	print "comparing ".$tab[0]." with ".$piletab[0]."\n";
#	print "check if position ".$piletab[1]." lies within repeat with end ".$tab[2]."\n"; 
#	if($tab[0] eq $piletab[0]){
#		print "scaffold no is the same!\n";
#	}
#	if($piletab[1]<=$tab[2]) {
#		print "number is lower than end\n";
#	}

	my $rep_scafNo = $tab[0];
	my $pile_scafNo = $piletab[0];
	$rep_scafNo =~ s/S//;
	$pile_scafNo =~ s/S//;
	while($pile_scafNo<$rep_scafNo) {
		print OUT $pile;
		if(eof(PIL)) {
			last;
		}	
		$pile = <PIL>;
		@piletab = split(/\t/, $pile);
		$pile_scafNo = $piletab[0];
		$pile_scafNo =~ s/S//;
	}

	while($tab[0] eq $piletab[0] && $piletab[1]<=$tab[2]) {

		if($piletab[1]>=$tab[1]) {
			chomp($pile);
			print OUT $pile."\t"."R\n";
		}
		else {
			print OUT $pile;
		}
		if(eof(PIL)) {
			last;
		}	
		$pile = <PIL>;
		@piletab = split(/\t/, $pile);
	}
	seek(PIL, -length($pile), 1);
}
close(IN);

while(<PIL>) {
	print OUT $_;
}

close(PIL);
close(OUT);

