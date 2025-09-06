#!/usr/bin/perl

# # # # # #
# compareTwoFastaBetweenPos.pl
# written by Linnéa Smeds                     Oct 2012 
# ====================================================
# Takes a file with scaffold, start and stop for two
# different fasta files, and compare if the sequence
# is the same (only print rows where the sequences are
# different).
# ====================================================


use warnings;
use strict;
$|=1;
use Data::Dumper;
use Bio::DB::Fasta;

# Input parameters
my $INFILE = $ARGV[0];
my $FASTA1 = $ARGV[1];
my $FASTA2 = $ARGV[2];

my $DEBUG = 0;
my $db1      = Bio::DB::Fasta->new($FASTA1);
my $db2      = Bio::DB::Fasta->new($FASTA2);

open(IN, $INFILE);
while(<IN>) {
	my ($scaffold, $start, $end, $scaffold2, $start2, $end2) = split(/\s+/, $_); 

	my $seq1 = $db1->seq("$scaffold",$start,$end);
	my $seq2 = $db2->seq("$scaffold2",$start2,$end2);

	if (uc($seq1) ne uc($seq2)){
		print ">$scaffold:$start:$end:$scaffold2:$start2:$end2 ", $end-$start+1, "\n";
		for ( my $pos = 0 ; $pos < length($seq1) ; $pos += 60 ) {
			print substr($seq1, $pos, 60), "\t", substr($seq2, $pos, 60), "\n";
	 	}
	}
} 
