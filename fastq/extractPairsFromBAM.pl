#!/usr/bin/perl

# extractPairsFromBAM.pl
# written by Linnéa Smeds                        June 2014
# ========================================================
# Takes a bam file and a list of wanted reads, and prints
# the pairs in fastq format. Saves the pairs in a hash, so
# this script need a lot of memory in case the read list 
# is long.
# NOTE: SAMTools need to be loaded before 
# ========================================================


use strict;
use warnings;

my $BAM = $ARGV[0];
my $readList = $ARGV[1];
my $outpref = $ARGV[2];
# optional: 
my $REGION = $ARGV[3];

unless($REGION) {
	$REGION="";
}

my $time = time;

my %reads = ();
open(LST, $readList);
while(<LST>) {
	chomp($_);
	$reads{$_}{'seq1'}="1";
}
close(LST);

my $hashCnt = scalar(keys %reads);
print "There are $hashCnt different pairs on the list\n";

my $out1 = $outpref.".pair1.fastq";
my $out2 = $outpref.".pair2.fastq";

open(OUT1, ">$out1");
open(OUT2, ">$out2");

my $totCnt=0;
my $cnt=0;
open(BAM, "samtools view $BAM $REGION|");
while(<BAM>) {

	my @tab = split(/\s+/, $_);
	my $id = $tab[0];

	# Read is present in the list
	if(defined $reads{$id}) {
		
		#Read is first in pair
		if($tab[1]<128){
			$reads{$id}{'seq1'}=$tab[9];
			$reads{$id}{'qual1'}=$tab[10];
			
		}
		# Read is second in pair
		else {
			$reads{$id}{'seq2'}=$tab[9];
			$reads{$id}{'qual2'}=$tab[10];
		}
		$cnt++;		
	}
	
	if ($totCnt%100000==0) {
		print "$totCnt reads processed\r";
	}

	# Check if all reads are found (can save time for big bam files)
	if($cnt==$hashCnt) {
		last;	
	}
	$totCnt++;	
}

# Print all reads
foreach my $key (keys %reads) {
	if($reads{$key}{'seq1'} eq "1") {
		print STDERR "$key is not found in bamfile!\n";
	}
	else {
		print OUT1 $key."/1\n".$reads{$key}{'seq1'}."\n+\n".$reads{$key}{'qual1'}."\n";
		print OUT2 $key."/2\n".$reads{$key}{'seq2'}."\n+\n".$reads{$key}{'qual2'}."\n";
	}
}

close(OUT1);
close(OUT2);
close(BAM);

$time = time - $time;
print "Time elapsed: $time sec.\n";
