#!/usr/bin/perl

# get_paired_read_status.pl	  		
# written by Linnéa Smeds							
# ===================================================================
#
# ===================================================================	

# Packages
use strict;
use warnings;
use List::Util qw[min max];

#Inputfiles
my $READSTAT = $ARGV[0];
my $SCAFLEN = $ARGV[1];
my $PREF = $ARGV[2];

my %lengths = ();
open(LEN, $SCAFLEN);
while(<LEN>) {
	my @t = split(/\s+/, $_);
	$lengths{$t[0]}=$t[1];
}
close(LEN);
	

my $sameOUT = $PREF."_pairs_on_same_scaff.txt";
my $diffOUT = $PREF."_pairs_on_diff_scaff.txt";

open(SOUT, ">$sameOUT");
open(DOUT, ">$diffOUT");

# Goes through every read in the file
open(IN, $READSTAT);
<IN>;
<IN>;
while(<IN>) {
	my @t = split(/\s+/, $_);
	if ($t[0] =~ m/left/) {
		my ($read, $rest) = split("_", $t[0]);
		print "we have a pair: $read!\n";
		my $next = <IN>;
		my @t2 = split(/\s+/, $next);
		if($t2[0] !~ m/right/) {
			die "there are no right part for $read\n";
		}
		if(($t[1] eq "Full" || $t[1] eq "Partial") && 
		($t2[1] eq "Full" || $t2[1] eq "Partial")) { 	
			print "both reads in $read map to a scaffold\n";
			if($t[4] eq $t2[4]) {
				print "\t...and to the same scaffold as well\n";
				my $diff = max($t[5],$t[6],$t2[5],$t2[6])-min($t[5],$t[6],$t2[5],$t2[6]);
				print SOUT $read."\t".$t[4]."\t".$diff."\n";				
			}
			else {
				print "\t...but to different ones..\n";
				my $left2edge = min(($lengths{$t[4]}-max($t[5],$t[6])), min($t[5], $t[6]));
				my $right2edge = min(($lengths{$t2[4]}-max($t2[5],$t2[6])), min($t2[5], $t2[6]));
				my $sum = $left2edge+$right2edge;
				print DOUT $read."\t".$t[4]."\t".$left2edge."\t".$t2[4]."\t".$right2edge."\t".$sum."\n";
			}
		}
	}
}
	
