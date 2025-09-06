#!/usr/bin/perl

# 
# written by Linnéa Smeds                         Mar 2018
# modified from wipeOuptUnwantedMatseSAM.pl
# ========================================================
# Takes a samfile and a fasta with wanted scaffolds, and 
# only save header lines @SQ from this file. 
# NOTE: This doesn't filter the reads or fix mates if 
# reads are paired!
# ========================================================


use strict;
use warnings;

my $SAM = $ARGV[0];
my $FASTA = $ARGV[1];	#reference with approved scaffolds

my $time = time;

my %hash = ();
open(FST, $FASTA);
while(<FST>) {
	if(/^>/) {
		my @a=split(/\s+/, $_);
		my $scaf=$a[0];
 		$scaf=~s/>//;
		$hash{$scaf}=1;
	}
}
close(FST);

my $hashCnt = scalar(keys %hash);
print STDERR "There are $hashCnt scaffolds in the reference\n";

my $totCnt=0;
my ($badreadcnt,$badmatecnt)=(0,0);
open(SAM, $SAM);
while(<SAM>) {

	if(/^@/) {
		if(/^\@SQ/) {	#sequence header, check if it's in the hash!
			my @heads=split(/\s+/,$_);
			$heads[1]=~s/SN://;
			if(defined $hash{$heads[1]}) {
				print;
			}
		}
		else { 
			print;	#other header, always print
		}
	}
	else {
		print;
	}

}
close(SAM);
$time = time - $time;
print STDERR "Time elapsed: $time sec.\n";
