#!/usr/bin/perl

# # # # # #
# covWindowsFromPileup_repeatMasked_GCnotRM.pl
# written by Linnéa Smeds                     April 2011
#NOTE!!! THIS ONLY WORKS IF THE PILEUP FILE HAS THE
#REPEATS MARKED WITH "acgt" (SAME AS FASTA FILE!!)
# modified in January 2012 to include all bases 
# (not only the ones listed in pileup)
# modified in February 2012 to only look at non repeat
# bases.
# Modified 14 Jan 2014 to calculate GC from all bases,
# even though coverage is taken only from rm bases.
# Now also takes zipped pileup files.
# Modified 16 Jan 2014 to calc coverage as sum of cov
# divided by all non-atcgnN bases in wind (before, it
# was divided only by non-atcgnN in pileup). Repeat in
# summary was also updated to be calculated for non-N
# bases, and "n" is from now on counted as "N", not rep.
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
			my ($GC, $AT, $N, $reps, $ok) = (0, 0, 0, 0, 0);
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
				else {
					$ok++;
				}
				# checking GC, AT, N regardless of above 				
				if($base =~ m/[AT]/i) {
					$AT++;
				}
				elsif($base =~ m/[GC]/i) {
					$GC++;
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
			$windows{$scaffold}{$i}{'ok'} = $ok;
			$windows{$scaffold}{$i}{'end'} = $end;
	#		print $scaffold."\t".$i."\t".$end."\t".$GCcont."\t".$repcont."\t".$N."\n";
		}
	}
}
close(SEQ);


#Open pileup file
if($pileup =~ m/.gz$/) {
	open(IN, "zcat $pileup |");
}
else {
	open(IN, $pileup);
}
my $next = <IN>;
my @line = split(/\s+/, $next);

#Go through all scaffolds in order..
foreach my $key (sort keys %windows) {
	my ($scafLen, $scafCov, $totBas, $scafGC, $scafRep, $scafN) = (0,0,0,0,0,0);

	#..and all windows for each scaffold
	foreach my $subkey (sort {$a<=>$b} keys %{$windows{$key}}) {
		my $totcov = 0; 
	#	print "first line has scaffold ".$line[0]." and position ".$line[1]."\n";
		while($line[0] eq $key && $line[1]<$subkey+$windowsize) {
			
			unless($line[2] =~ m/[atcgnN]/) {
				$totcov+=$line[3];
			}
			
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
			@line = split(/\s+/, $next);
		}
		my $meancov = "noCov";
		unless($windows{$key}{$subkey}{'ok'}==0) {
			$meancov = $totcov/$windows{$key}{$subkey}{'ok'};
		}
		# Old version, GC was checked on non repeatMasked regions
		#my $meanGC = "noBases";
		#unless($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'}-$windows{$key}{$subkey}{'rep'}==0) {
			#$meanGC = $windows{$key}{$subkey}{'gc'}/($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'}-$windows{$key}{$subkey}{'rep'});
		#}
 		my $meanGC = "OnlyNs";
		my $meanRep = "OnlyNs";
		unless(($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'})==0) {
			$meanGC = $windows{$key}{$subkey}{'gc'}/($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'});
			$meanRep = $windows{$key}{$subkey}{'rep'}/($windows{$key}{$subkey}{'end'}-($subkey-1)-$windows{$key}{$subkey}{'N'});
		}
	
		print OUT $key."\t".$subkey."\t".$windows{$key}{$subkey}{'end'}.
					"\t".$meancov."\t".$meanGC."\t".$meanRep.
					"\t".$windows{$key}{$subkey}{'N'}."\n";
			
		$scafLen+=($windows{$key}{$subkey}{'end'}-($subkey-1));
		$scafCov+=$totcov;
		$totBas+=$windows{$key}{$subkey}{'ok'};
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
	my $scafMeanRep = $scafRep/($scafLen-$scafN);

	print SUM $key."\t".$scafLen."\t".$scafMeanCov."\t".$scafMeanGC.
				"\t".$scafMeanRep."\t".$scafN."\n";

	delete $windows{$key};
}


