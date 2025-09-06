#!/usr/bin/perl

# # # # #
# splitFastaFileToPieces.pl        
# written by Linnéa Smeds 		   8 november 2010
# ========================================================
# Takes a fasta file and splits it into several smaller 
# files with a given no of sequences in each. The output
# files are called prefix_start_end.fa, and are placed in
# an given directory.
# EDIT: ONLY WORKS WITH FASTA FILE THAT HAS THE SEQUENCE
# ON ONE LINE!!!
# ========================================================
# usage perl 

use strict;
use warnings;

my $time = time;

# Input parameters
my $fasta = $ARGV[0];
my $seqPerFile = $ARGV[1];
my $prefix = $ARGV[2];
my $outDir = $ARGV[3];

my $wcLine = `grep ">" $fasta |wc`;
my @a = split(/\s+/, $wcLine);
my $seqNo = $a[1]; 
my $cnt = 0;
print "Total number of seq is $seqNo\n";
print "Start printing to files.\n";
print "Processing sequence:\n";
$| = 1;


while($cnt<$seqNo) {
	my ($end,$takeLast);
	if($cnt+$seqPerFile < $seqNo) {
		$end = $cnt+$seqPerFile;
		$takeLast = $seqPerFile*2;
	}
	else {
		$end = $seqNo;
		$takeLast = ($seqNo-$cnt)*2;
	}
	my $start =$cnt+1;
	my $file = $prefix."_".$start."_".$end.".fa";
	my $lines = $end*2;
	system("head -n$lines $fasta|tail -n$takeLast >$outDir/$file");
	$cnt+=$seqPerFile;
	print "\r$end";
}
$time = time-$time;
print "\nDone in $time seconds.\n";


