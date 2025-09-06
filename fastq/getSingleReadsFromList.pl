#!/usr/bin/perl

# getSingleReadsFromList.pl
# written by Linnéa Smeds                         May 2011
# ========================================================
# Takes a signle fastq files and extract all reads that 
# are listed in a given file.
# ========================================================
# usage perl 

use strict;
use warnings;

my $in1 = $ARGV[0];
my $readList = $ARGV[1];

my $time = time;

my %reads = ();
open(LST, $readList);
while(<LST>) {
	chomp($_);
	$reads{$_}=1;
}
close(LST);

open(IN1, $in1);

my $totCnt=0;
my $saveCnt=0;
while(<IN1>) {

	my $id = $_;
	my $seq=<IN1>;
	my $plus=<IN1>;
	my $score=<IN1>;

	$id =~ s/@//;
	$id =~ s/\/\d//;
	chomp($id);

	if(defined $reads{$id}) {
		print  $_ . $seq . $plus . $score;
		$saveCnt++;
	}
	$totCnt++;
}
close(IN1);

#print "In total $saveCnt pairs out of $totCnt were saved\n";
#$time = time - $time;
#print "Time elapsed: $time sec.\n";
