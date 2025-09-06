#!/usr/bin/perl

# getReadsFromSAMFile.pl
# written by Linnéa Smeds                       March 2012
# ========================================================
# Takes a list of reads and extracts those from a SAMfile
# ========================================================
# usage perl 

use strict;
use warnings;

my $readList = $ARGV[0];
my $SAM = $ARGV[1];
my $output = $ARGV[2];

my $time = time;

my %reads = ();
open(LST, $readList);
while(<LST>) {
	chomp($_);
	$reads{$_}=1;
}
close(LST);

my $hashCnt = 0;
foreach my $key (keys %reads) {
	$hashCnt++;
}
print "There are $hashCnt different pairs on the list\n";


open(IN, $SAM);
open(OUT, ">$output");

my $totCnt=0;
my $saveCnt=0;
while(<IN>) {
	my @tab = split(/\s+/, $_);
	
	if(defined $reads{$tab[0]}) {
		print OUT $_;
		$saveCnt++;
	}
	$totCnt++;
}
close(OUT);
close(IN);

print "In total $saveCnt pairs out of $totCnt were saved\n";
$time = time - $time;
print "Time elapsed: $time sec.\n";
