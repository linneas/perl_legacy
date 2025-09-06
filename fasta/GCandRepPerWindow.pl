#!/usr/bin/perl

# # # # # #
# GCandRepPerWindow.pl
# written by Linnéa Smeds                   16 jan 2014
# Modified from covWindowFromPileup_repeatMasked_GCnotRep.pl
# But only do the first part of going through the fasta
# and calculates GC and repeat content (of non N bases) 
# =====================================================
# RepeatMasked bases need to be written as a, c, g, t.
# Small Ns "n" are treated as "N" to avoid confusion
# (in previous versions, n was treated as both repeat
# and N which could mess up the calculations). 
# =====================================================
# Usage: perl covWindowsFromPileup.pl <fasta> \
#			<window size> <output prefix>
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $fasta = $ARGV[0];
my $windowsize = $ARGV[1];
my $prefix = $ARGV[2];

# Output files
my $windowOut = $prefix.".".$windowsize.".stats.txt";
my $sumOut = $prefix.".summary.stats.txt";
open(OUT, ">$windowOut");
open(SUM, ">$sumOut");
print OUT "SEQ\tWSTART\tWEND\tGCCONT\tREPCONT\tNs\n";
print SUM "SEQ\tLENGTH\tGCCONT\tREPCONT\tNs\n";

# Ge through the fasta file
open(SEQ, $fasta);
while(<SEQ>) {
	if(/>/) {
		my @line = split(/\s+/, $_);
		my $scaffold = $line[0];
		$scaffold =~ s/>//;

		#Add all sequence lines to one string without newlines
		my $seq;
		my $next = <SEQ>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(SEQ)) {
				last;
			}	
			$next = <SEQ>;
		}
		seek(SEQ, -length($next), 1);

		my $scaflen=length($seq);
		my ($totrep, $totGC, $totN, $totNonN) = (0,0,0,0);

		for(my $i=1; $i<length($seq); $i+=$windowsize) {
			my ($GC, $AT, $N, $reps) = (0, 0, 0, 0);
			my $end = min($i+$windowsize-1, length($seq));
			my @tempseq=split(//, substr($seq, $i-1, $end-($i-1)));
			while(scalar(@tempseq)>0) {
				my $base = shift(@tempseq);
				if($base =~ m/[atcg]/) {
					$reps++;
				}
				elsif($base =~ m/[nN]/) {
					$N++;
				}

				# checking GC regardless of above 				
				if($base =~ m/[GC]/i) {
					$GC++;
				}
				elsif($base =~ m/[AT]/i) {
					$AT++;
				}
			}
		
			my $meanGC = "OnlyNs";
			my $meanRep = "OnlyNs";
			my $nonN=$GC+$AT;
			unless($nonN==0) {
				$meanGC = $GC/$nonN;
				$meanRep = $reps/$nonN;
			}
			print OUT $scaffold."\t".$i."\t".$end."\t".$meanGC."\t".$meanRep."\t".$N."\n";
			
			$totrep+=$reps;
			$totGC+=$GC;
			$totN+=$N;
			$totNonN+=$nonN;
		}
	
		my $avgGC = "OnlyNs";
		my $avgRep = "OnlyNs";
		unless($totNonN==0) {
			$avgGC=$totGC/$totNonN;
			$avgRep=$totrep/$totNonN;
		}
		print SUM $scaffold."\t".$scaflen."\t".$avgGC."\t".$avgRep."\t".$totN."\n";
	}
}
close(SEQ);


