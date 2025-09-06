#!/usr/bin/perl


# # # # # #
# changeFastaHeaders.pl
# written by Linnéa Smeds                 21 May 2011
# ===================================================
# Takes a fasta file and a map file with the old and
# the new values in separate columns, and changes the
# fasta headers according to this.
# ===================================================
# Usage: 

use strict;
use warnings;


# Save the starting time
my $time = time;

# Input parameters
my $fasta = $ARGV[0]; 	
my $mapfile = $ARGV[1];		
my $output = $ARGV[2];


my %hashmap = ();
open(MAP, $mapfile);
while(<MAP>) {
	chomp($_);
	my ($old, $new) = split(/\t/, $_);
	$hashmap{$old}=$new;
}
close(MAP);


open(OUT, ">$output");

open(IN, $fasta);
my $printflag = "off";
while(<IN>) {
	if(/^>/) {
		my $head = $_;
		chomp($head);
		$head =~ s/>//;

		if(defined $hashmap{$head}) {
			print OUT ">".$hashmap{$head}."\n";
			$printflag = "on";
		}
		else {
			print "there was no $head in the map file\n";
			$printflag = "off";
		}
	}
	else {
		if($printflag eq "on") {
			print OUT $_;
		}
	}
}
close(IN);
close(OUT);

$time = time-$time;
print "Time elapsed: $time sec\n";
