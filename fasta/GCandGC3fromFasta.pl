#!/usr/bin/perl

my $usage = "
# # # # # #
# GCandGC3fromFasta.pl
# written by Linnéa Smeds                4 December 2014
# ======================================================
# Calculates the GC-distribution and GC3 per sequence 
# and/or in total (Running with \"fast\" flag is faster 
# and only returns the total number of GC and GC3.
# ======================================================
# Usage: perl GCDistrFromFasta.pl <fastafile> <slow|fast>
#			<outpref>
#
# Example 1: perl GCandGC3fromFasta.pl mySeqs.fa fast
# 	(Returns the total number GC and GC3)
# Example 2: perl GCandGC3fromFasta.pl mySeqs.fa slow prefix
# 	(Returns prefix.GCcontent.txt with a list of all 
#	sequences and their GC and GC3 content.)
";

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 
my $flag = $ARGV[1];
my $outpref = $ARGV[2];

my $time = time;

my $listOut;

if(defined $flag) {
	if($flag eq "slow"){
		if(defined $outpref) {
			$listOut = $outpref.".GCcontent.txt";
		}
		else {
			$listOut = $fasta.".GCcontent.txt";
		}
		open(OUT, ">$listOut");
		print OUT "SCAFFOLD\tNON-N_LEN\tSUM_GC\tFRAC_GC\tSUM_GC3\tFRAC_GC3\n";
	}
	elsif($flag eq "fast") {
	}
	else {
		die "Flag must be either \"slow\" or \"fast\"\n\n$usage";
	}
}
else {
	$flag="fast";
	print "No run type was given! Will perform a fast run with only summaries.\n";
	print "If per sequence GC is desired, run with \"slow\" as second input.\n";
}


open(IN, $fasta);
my ($head, $seq) = ("","");
my $seqcnt=0;
my ($totsum, $totbases, $totGC3, $totGC3bases) = (0,0,0,0);
while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		$head = $tab[0];
		chomp($head);
		$head =~ s/>//;
		$seq = "";
		my $scafsum = 0;
		my $scafGC3 = 0;
		my $Ns = 0;
		$seqcnt++;

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

		my $length = length($seq);

		#Sum up the numbers of Gs and Cs
		my @Ghits = $seq =~ m/(G+)/gi;
		for(@Ghits) {
			$scafsum+=length($_);
		}
		my @Chits = $seq =~ m/(C+)/gi;
		for(@Chits) {
			$scafsum+=length($_);
		}
		my @Nhits = $seq =~ m/(N+)/gi;
		for(@Nhits) {
			$Ns+=length($_);
		}
		$length = $length-$Ns;

		# Sum up the GC3
		my $lenGC3 = 0;
		my @bases=split(//, $seq);
		for (my $i=2; $i<scalar(@bases); $i+=3) {
			if($bases[$i] =~ m/[GC]/i) {
				$scafGC3++;
			}
			unless($bases[$i] =~ m/N/i) {
				$lenGC3++;
			}
		}

		# Print per sequence statistics if wanted
		if($flag eq "slow") {
			my $frac = $scafsum/$length;
			my $GC3frac=$scafGC3/$lenGC3;
			print OUT $head."\t".$length."\t".$scafsum."\t".$frac."\t".$scafGC3."\t".$GC3frac."\n";
		}
	
		$totsum+=$scafsum;
		$totbases+=$length;
		$totGC3+=$scafGC3;
		$totGC3bases+=$lenGC3;
	}
}
close(IN);
close(OUT);

print "DEBUG: #GC3 is $totGC3 and total number of third positions are $totGC3bases\n";

my $percent = 100*($totsum/$totbases);
$percent = sprintf "%.2f", $percent;
my $GC3percent = 100*($totGC3/$totGC3bases);
$GC3percent = sprintf "%.2f", $GC3percent;


$time = time-$time;

print "Total number of GC: $totsum bp out of $totbases bp ($percent%)\n";
print "Total number of GC3: $totGC3 bp out of $totGC3bases bp ($GC3percent%)\n";
print "Total number of sequences: $seqcnt\n";
print "Total time elapsed: $time sec\n";
