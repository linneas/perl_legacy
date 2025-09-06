#!/usr/bin/perl

# # # # # #
# covWindowsFromPileup_repeatMasked.pl
# written by Linnéa Smeds                     April 2011
# modified in January 2012 to include all bases 
# (not only the ones listed in pileup)
# modified in February 2012 to only look at non repeat
# bases.
# =====================================================
# Takes an assembly fasta file and saves the GC and N
# content for each window, then goes through the pileup 
# file (with the first four columns from mpileup (scaff,
# position, base, cov) and add the coverage per window, 
# but only for bases that are not repeatmasked (only 
# count capital letters, and ignores "small" repeat
# letters a, t, c, g, n (and also ignores N).
# =====================================================
# Usage: perl covWindowsFromPileup.pl <fasta> <pileup> 
#			<window size> <output prefix>
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $fasta = $ARGV[0];
my $pileup = $ARGV[1];
my $windowsize = $ARGV[2];
my $prefix = $ARGV[3];

# Output files
my $windowOut = $prefix."_".$windowsize.".cov";
my $sumOut = $prefix."_"."summary.cov";
open(OUT, ">$windowOut");
open(SUM, ">$sumOut");
print OUT "SEQ\tWSTART\tWEND\tMEANCOV\tGCCONT\tREPCONT\tNs\n";
print SUM "SEQ\tLENGTH\tMEANCOV\tGCCONT\tREPCONT\tNs\n";

my %windows = ();
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

		my $totcnt = 0;
		my $i;

		for($i=1; $i<length($seq); $i+=$windowsize) {
			my ($GC, $AT, $N, $reps) = (0, 0, 0, 0);
			my $end = min($i+$windowsize-1, length($seq));
			my @tempseq=split(//, substr($seq, $i-1, $end-($i-1)));
			while(scalar(@tempseq)>0) {
				my $base = shift(@tempseq);
				if($base =~ m/[atcgn]/) {
					$reps++;
				}
				else {
					if($base =~ m/[AT]/i) {
						$AT++;
					}
					elsif($base =~ m/[GC]/i) {
						$GC++;
					}
					else{
						$N++;
					}
				}
			}
	#		my $GCcont = "noBases";
	#		unless($GC+$AT==0) {
	#			$GCcont = $GC/($GC+$AT);
	#		}
	#		my $repcont = $reps/($GC+$AT+$N);
			$windows{$scaffold}{$i}{'gc'} = $GC;
			$windows{$scaffold}{$i}{'rep'} = $reps;
			$windows{$scaffold}{$i}{'N'} = $N;
			$windows{$scaffold}{$i}{'end'} = $end;
	#		print $scaffold."\t".$i."\t".$end."\t".$GCcont."\t".$repcont."\t".$N."\n";
		}
	}
}
close(SEQ);


#Open pileup file
open(IN, $pileup);
my $next = <IN>;
my @line = split(/\s+/, $next);

#Go through all scaffolds in order..
foreach my $key (sort keys %windows) {
	my ($scafLen, $scafCov, $totBas, $scafGC, $scafRep, $scafN) = (0,0,0,0,0,0);

	#..and all windows for each scaffold
	foreach my $subkey (sort {$a<=>$b} keys %{$windows{$key}}) {
		my ($totcov, $totcnt) = (0, 0); 
	#	print "first line has scaffold ".$line[0]." and position ".$line[1]."\n";
		while($line[0] eq $key && $line[1]<$subkey+$windowsize) {
			
			unless($line[2] =~ m/[atcgnN]/) {
				$totcov+=$line[3];
				$totcnt++;
			}
			
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
			@line = split(/\s+/, $next);
		}
		my $meancov = "noCov";
		unless($totcnt==0) {
			$meancov = $totcov/$totcnt;
		}
		my $meanGC = "noBases";
		unless($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'}-$windows{$key}{$subkey}{'rep'}==0) {
			$meanGC = $windows{$key}{$subkey}{'gc'}/($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'}-$windows{$key}{$subkey}{'rep'});
		}
		my $meanRep = $windows{$key}{$subkey}{'rep'}/($windows{$key}{$subkey}{'end'}-($subkey-1));
	
		print OUT $key."\t".$subkey."\t".$windows{$key}{$subkey}{'end'}.
					"\t".$meancov."\t".$meanGC."\t".$meanRep.
					"\t".$windows{$key}{$subkey}{'N'}."\n";
			
		$scafLen+=($windows{$key}{$subkey}{'end'}-($subkey-1));
		$scafCov+=$totcov;
		$totBas+=$totcnt;
		$scafGC+= $windows{$key}{$subkey}{'gc'};
		$scafRep+=$windows{$key}{$subkey}{'rep'};
		$scafN+=$windows{$key}{$subkey}{'N'};
		delete $windows{$key}{$subkey};

	}

	my $scafMeanCov = "noCov";
	unless ($totBas==0) {
		 $scafMeanCov=$scafCov/$totBas;
	}
	my $scafMeanGC = "noBases";
	unless ($scafLen-$scafN==0) {
		$scafMeanGC=$scafGC/($scafLen-$scafN);
	}
	my $scafMeanRep = $scafRep/$scafLen;

	print SUM $key."\t".$scafLen."\t".$scafMeanCov."\t".$scafMeanGC.
				"\t".$scafMeanRep."\t".$scafN."\n";

	delete $windows{$key};
}


