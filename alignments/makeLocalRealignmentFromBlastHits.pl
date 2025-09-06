#!/usr/bin/perl

# makeLocalRealignmentFromBlastHits.pl
# written by Linnéa Smeds                          Nov 2012
# =========================================================
# Takes a list with blast hits and the two original fasta
# files, extracts the hits and performs local realignment
# of the sequences. Then prints base-to-base correspondance
# list.  
#
# The blast file should have sequence name, start and stop
# for each species respectively:
# SEQ1	START1	STOP1	SEQ2	START2	STOP2
# scaf1	100	200	chr1	4000	4102	
# =========================================================
# Usage: perl makeLocalRealignmentFromBlastHits.pl <BLAST LIST> \
#					<FASTA1> <FASTA2> <OUTPUT>
#
#

use strict;
use warnings;
use List::Util qw[min max];
use Bio::DB::Fasta;

# Input parameters
my $BLASTLIST = $ARGV[0];
my $FASTA1 = $ARGV[1];
my $FASTA2 = $ARGV[2];
my $OUTPUT = $ARGV[3];

# Open output
open(OUT, ">$OUTPUT");

# Make databases of the fasta files
my $db1 = Bio::DB::Fasta->new($FASTA1);
my $db2 = Bio::DB::Fasta->new($FASTA2);


# Go through the list and extract one region at the time
open(IN, $BLASTLIST);
while(<IN>) {
	my ($scaf1, $start1, $stop1, $scaf2, $start2, $stop2) = split(/\s+/,$_);

	# Extract from fasta
	my $seq1 = $db1->seq("$scaf1",$start1,$stop1);
	my $seq2 = $db2->seq("$scaf2",$start2,$stop2);

#	print "looking up sequence $scaf1, getting $seq1\n";
#	print "looking up sequence $scaf2, getting $seq2\n";

	open(TMP, ">temp.fa");
	print TMP ">seq1\n$seq1\n";
	print TMP ">seq2\n$seq2";
	close(TMP);

	#Mafft alignment method "linsi" is the most accurate one
	system("linsi temp.fa >temp.align 2>mafft.out");

	#Open the output and read in the aligned sequences
	open(ALN, "temp.align");
	my @alignments = ();
	my $cnt = 0;
	while(my $line = <ALN>) {
		if($line =~ m/>/) {
			my $seq = "";
			my $next = <ALN>;
			print "next is now $next\n";
			while ($next !~ m/^>/) {
				chomp($next);
				$seq .= $next;
				if(eof(ALN)) {
					last;
				}	
				$next = <ALN>;
			}
			seek(ALN, -length($next), 1);
			$alignments[$cnt] = $seq;
			print "saved $seq in alignments [ $cnt ] \n";
			$cnt++;
			
		}
	}
	
	
	#Compare the sequences one position at the time
	my @al1 = split(//, $alignments[0]);
	my @al2 = split(//, $alignments[1]);
	my $pos1 = $start1-1;
	my $pos2 = $start2-1;

	for (my $i=0; $i<scalar(@al1); $i++) {

		if($al1[$i] ne "-") {
			$pos1++;
		}
		if($al2[$i] ne "-") {
			$pos2++;
		}
		if($al1[$i] ne "-" && $al2[$i] ne "-") {
			print OUT $scaf1."\t".$pos1."\t".$scaf2."\t".$pos2."\n";
		} 

	}

}
close(IN);


