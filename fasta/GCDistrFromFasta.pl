#!/usr/bin/perl

my $usage = "
# # # # # #
# GCDistrFromFasta.pl
# written by Linnéa Smeds 19 oct 2010
# ======================================================
# Calculates the GC-distribution per sequence and/or in 
# total (Running with \"fast\" flag is faster and only
# returns the total number of GC.
# ======================================================
# Usage: perl GCDistrFromFasta.pl <fastafile> <slow|fast>
#			<outpref>
#
# Example 1: perl NDistrFromFasta.pl mySeqs.fa fast
# 	(Returns the total number of Ns in file)
# Example 2: perl NDistrFromFasta.pl mySeqs.fa slow prefix
# 	(Returns prefix.gaps with a list of all gaps (start,
# 	stop and length), and a prefix.gaphist with the gap 
# 	size distribution: column1 = gap size,
#	column2 = #gap of this size)
";

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 
my $flag = $ARGV[1];
my $outpref = $ARGV[2];

my $time = time;

my ($listOut, $histOut);

if($flag eq "slow"){
	if(defined $outpref) {
		$listOut = $outpref.".GCcontent.txt";
	}
	else {
		$listOut = $fasta.".GCcontent.txt";
	}
}
elsif($flag eq "fast") {
}
else {
	die "Flag must be either \"slow\" or \"fast\"\n\n$usage";
}

open(IN, $fasta);
if($flag eq "slow") {
	open(OUT, ">$listOut");
}
my %hist = ();
my ($head, $seq) = ("","");
my ($totsum, $totbases) = (0,0);
my $seqcnt=0;
while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		$head = $tab[0];
		chomp($head);
		$head =~ s/>//;
		$seq = "";
		my $scafsum = 0;
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

		if($flag eq "slow") {
			if($length>0){			# Added Aug 20, 2015 to handle sequences with only Ns (they are not printed at all)
				my $frac = $scafsum/$length;
				print OUT $head."\t".$length."\t".$scafsum."\t".$frac."\n";
			}
		}
	
		$totsum+=$scafsum;
		$totbases+=$length;
	}
}
close(IN);
close(OUT);


my $percent = 100*($totsum/$totbases);
$percent = sprintf "%.2f", $percent;
$time = time-$time;

print "Total number of GC: $totsum bp out of $totbases bp ($percent%)\n";
print "Total number of sequences: $seqcnt\n";
print "Total time elapsed: $time sec\n";
