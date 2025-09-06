#!/usr/bin/perl

# # # # # # 
# checkEndsForNs.pl               
# written by Linnéa Smeds                     25 April 2012
# =========================================================
# Takes a fasta file and checks the ends for N sequences. 
# If there are many Ns nearby the end, the sequence is 
# trimmed until a long stretch of ACGT-characters is found.
# =========================================================
# usage perl 

use strict;
use warnings;

my $fasta = $ARGV[0];
my $ACGTthres = $ARGV[1];
my $output = $ARGV[2];

my $time = time;

open(IN, $fasta);
open(OUT, ">$output");

while(<IN>) {
	
	if($_ =~ m/^>/) {
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

		#Checking the beginning of the sequence:
		my @bases = split(//, $seq);
		my $nobases = 0;
		my $consecACGT = 0;
		
		my $this = shift @bases; 
		while($consecACGT <= $ACGTthres && scalar(@bases)>0) {
			if($this =~ m/[ATCG]/) {
				$consecACGT++;
			}
			else {
				$consecACGT=0;
			}
			$this = shift @bases; 
			$nobases++;
		}
		#if all bases are trimmed 
		if(scalar(@bases)==0) {
			print "No bases left - remove $head";
		}
		else {
		
			#if consecACGT is the same as nobases, don't do anything
			unless($nobases==$consecACGT) {
				my $removeNo = $nobases-$consecACGT;
				print "removing $removeNo from start of sequence $head";
				$seq = substr($seq, $removeNo, length($seq)-$removeNo);
			}

			#Checking the end of the sequence:
			@bases = split(//, $seq);
			$nobases = 0;
			$consecACGT = 0;
		
			$this = pop @bases; 
			while($consecACGT <= $ACGTthres) {
				if($this =~ m/[ATCG]/) {
					$consecACGT++;
				}
				else {
					$consecACGT=0;
				}
				$this = pop @bases; 
				$nobases++;
			}
			unless($nobases==$consecACGT) {
				my $removeNo = $nobases-$consecACGT;
				print "removing $removeNo from end of sequence $head\n";
				$seq = substr($seq, 0, length($seq)-$removeNo);
			}

			#Printing the sequence
			print OUT $head;
			my @blocks = split(/(.{80})/i, $seq);
			foreach my $b (@blocks) {
				if($b ne "") {
					print OUT "$b\n";
				}
			}
		}
	}
}
close(IN);

$time = time - $time;
print "Time elapsed: $time sec.\n";
