#!/usr/bin/perl

my $usage = "
# # # # # #
# RepDistrFromFasta.pl
# written by Linnéa Smeds 19 oct 2010
# ======================================================
# Calculates the repeat -distribution per sequence and/
# or in total (Running with \"fast\" flag is faster and 
# only returns the total number of repeats.
# ======================================================
# Usage: perl RepDistrFromFasta.pl <fastafile> <slow|fast>
#			<outpref>
#
# Example 1: perl RepDistrFromFasta.pl mySeqs.fa fast
# 	(Returns the total number of repeats in file)
# Example 2: perl RepDistrFromFasta.pl mySeqs.fa slow prefix
# 	(Returns prefix.Repcontent.txt with a list of all scaffolds
#	and their repeat content)
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
		$listOut = $outpref.".Repcontent.txt";
	}
	else {
		$listOut = $fasta.".Repcontent.txt";
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
while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		$head = $tab[0];
		chomp($head);
		$head =~ s/>//;
		$seq = "";
		my $scafsum = 0;
		my $Ns = 0;

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

		#Sum up the numbers of repeats
		my @hits = $seq =~ m/([agct]+)/g;
		for(@hits) {
			$scafsum+=length($_);
		}
		# sum up the number of Ns
		my @Nhits = $seq =~ m/(N+)/gi;
		for(@Nhits) {
			$Ns+=length($_);
		}

		$length = $length-$Ns;
		my $frac = $scafsum/$length;
		
		if($flag eq "slow") {
			print OUT $head."\t".$length."\t".$scafsum."\t".$frac."\n";
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

print "Total number of repeats: $totsum bp out of $totbases bp ($percent%)\n";
print "Total time elapsed: $time sec\n";
