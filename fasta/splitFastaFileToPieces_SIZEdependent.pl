#!/usr/bin/perl

# # # # #
# splitFastaFileToPieces_SIZEdependent.pl        
# written by Linnéa Smeds 		   8 november 2010
# ========================================================
# Takes a fasta file and splits it into several smaller 
# files with a given no of sequences in each. The output
# files are called prefix_start_end.fa, and are placed in
# an given directory.
# ========================================================
# usage perl 

use strict;
use warnings;

my $time = time;

# Input parameters
my $fasta = $ARGV[0];
my $seqPerFile = $ARGV[1];
my $amountPerFile = $ARGV[2];
my $prefix = $ARGV[3];
my $outDir = $ARGV[4];

my $wcLine = `grep ">" $fasta |wc`;
my @a = split(/\s+/, $wcLine);
my $seqNo = $a[1]; 
my $cnt = 0;
my $amount = 0;
print "Total number of seq is $seqNo\n";
print "Start printing to files.\n";
print "Processing sequence:\n";
$| = 1;

my $currentBlock = "";
my ($blockStart, $blockEnd, $blockNum) = (1,0,0);

open(IN, $fasta);


while(<IN>) {
	my $head = $_;	
	my $seq = "";
	my $next = <IN>;

	while ($next !~ m/^>/) {
		chomp($next),
		$seq.= $next;
		if(eof(IN)) {
			last;
		}	
		$next = <IN>;
	}
	seek(IN, -length($next), 1);
	
	$amount += length($seq);
	$cnt++;
	#print "amount is now $amount\n";
	print "\r$cnt";
	
	if($amount<$amountPerFile && $blockNum<$seqPerFile) {
		$currentBlock .= $head.$seq."\n";
		$blockEnd++;
		$blockNum++;
	}
	else {
		my $file = $outDir."/".$prefix."_".$blockStart."_".$blockEnd.".fa";
		open(OUT, ">$file");
		print OUT $currentBlock;	
		close(OUT);
		$currentBlock = $head.$seq."\n";
		($blockStart, $blockEnd)=($cnt, $cnt);
		$amount = length($seq);
		$blockNum=1;
	}
	
}
my $file = $outDir."/".$prefix."_".$blockStart."_".$blockEnd.".fa";
open(OUT, ">$file");
print OUT $currentBlock;	
close(OUT);
$time = time-$time;
print "\nDone in $time seconds.\n";


