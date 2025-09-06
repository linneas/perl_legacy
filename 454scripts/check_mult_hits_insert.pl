#!/usr/bin/perl

# # # # # # 
# check_mult_hits_insert.pl
# written by Linnéa Smeds                        21 Nov 2011
# ----------------------------------------------------------
# Description:
# 
# 
# ----------------------------------------------------------
#
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $LIST = $ARGV[0];
my $MERGE = $ARGV[1];
my $COORDS = $ARGV[2];
my $thres = $ARGV[3];
my $OUT = $ARGV[4];

my %refLength = ();
my %queryLength = ();
open(IN, $COORDS);
<IN>;<IN>;<IN>;<IN>;
while(<IN>) {
	my @t = split(/\s+/, $_);
	$refLength{$t[10]}=$t[6];
	$queryLength{$t[11]}=$t[7];
}
close(IN);

#my ($rstart, $rend, $qstart, $qend, $qproc, $ancCnt) = (0,0,0,0,0,0);
#my ($prevR, $prevQ) = ("","");

open(OUT, ">$OUT");
open(IN, $LIST);
while(<IN>) {
	my @t = split(/\s+/, $_);
	my $query = $t[0];
	my $bestRef = $t[1];
	my $secRef = $t[5];
	my $bestDistToEdge = 1000000000;
	my $secDistToEdge = 1000000000;

	system("grep \"$query\" $MERGE |grep \"$bestRef\" >temprows.txt");
	
	open(LST, "temprows.txt");
	while(<LST>) {
		my @n = split(/\s+/, $_);
		my $dist = min($n[0], abs($refLength{$bestRef}-$n[1]));
		if($dist<$bestDistToEdge) {
			$bestDistToEdge = $dist;
		}
	}
	close(LST);

	system("grep \"$query\" $MERGE |grep \"$secRef\" >temprows.txt");
	open(LST, "temprows.txt");
	while(<LST>) {
		my @n = split(/\s+/, $_);
		my $dist = min($n[0], abs($refLength{$secRef}-$n[1]));
		if($dist<$secDistToEdge) {
			$secDistToEdge = $dist;
		}
	}
	close(LST);

	print OUT "$query\t$bestRef\t$bestDistToEdge\t$secRef\t$secDistToEdge\n";
	
	if($bestDistToEdge < $thres) {
		if($secDistToEdge < $thres) {
			print "$query: Both hits lie close to the reference's edge.\n";
		}
		else {
			print "$query: One hit close to the reference's edge (major). Rearrangement!\n";
		}
	}
	else {	
		if($secDistToEdge < $thres) {
			print "$query: One hit close to the reference's edge (minor). Rearrangement!\n";
		}
		else {
			print "$query: Neither of the hits lie close to the edge. Rearrangement!\n";
		}
	}
}
close(IN);



