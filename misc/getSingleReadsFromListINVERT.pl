#!/usr/bin/perl

# getSingleReadsFromListINVERT.pl
# written by Linnéa Smeds                         May 2011
# ========================================================
# Takes a single fastq file and extract all reads that 
# are NOT listed on a given list.
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

while(<IN1>) {

	my $id = $_;
	chomp($id);
	my $seq=<IN1>;
	my $plus=<IN1>;
	my $score=<IN1>;
	
	$id =~ s/@//;
	$id =~ s/\/\d//;

	unless(defined $reads{$id}) {
		print  $_ . $seq . $plus . $score;

	}
}
close(IN1);


$time = time - $time;
print "Time elapsed: $time sec.\n";
