#!/usr/bin/perl

# # # # # #
# meanAndMedianCoverage_repeatMasked.pl
# written by Linnéa Smeds                    5 Nov 2013
# =====================================================
# Takes a fasta file with wanted sequences, a bed file
# with repeatRegions and a pileup with coverage, and 
# then calculates the mean and median coverage for each
# scaffold excluding the repeatRegions.
# =====================================================
# Usage: perl meanAndMedianCoverage_repeatMasked.pl


use strict;
use warnings;
use List::Util qw[min max];
#use Statistics::Basic qw(:all nofill);

# Input parameter
my $FASTA = $ARGV[0];
my $REPEATS = $ARGV[1];
my $PILEUP = $ARGV[2];
my $OUT = $ARGV[3];


# Save repeats
my %repeats = ();
open(REP, $REPEATS);
while(<REP>) {
	my @tab=split(/\s+/, $_);
	for(my $i=$tab[1]; $i<=$tab[2]; $i++) {
		$repeats{$tab[0]}{$i}=1;
# 		print "add pos $i to ".$tab[0]."\n";
	}
}
close(REP);

# Save non-repeat positions
my %genome = ();
open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/) {
		my @t = split(/\s+/, $_);
 	 	my $head = $t[0];
		$head=~s/>//;
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

		my $length=length($seq);

		for(my $i=1; $i<=$length; $i++){
			unless(defined $repeats{$head}{$i}) {
				$genome{$head}{$i}=0;
#				print "add pos $i to $head\n";
			}
		}
		delete $repeats{$head};
	}
}
close(IN);
%repeats = ();	# Deleting the rest of the repeats (if any)


# Go through pileup and add coverage
open(PILE, $PILEUP);
while(<PILE>) {
	my @tab=split(/\s+/, $_);
	if(defined $genome{$tab[0]}{$tab[1]}) {
		$genome{$tab[0]}{$tab[1]}=$tab[3];
	}
}
close(PILE);

# Go through the hash
open(OUT, ">$OUT");
foreach my $scaf (keys %genome) {
	my @arr;
	my $sum=0;
	my $n=keys %{$genome{$scaf}};
	my $mid=int($n/2);
#	print "there are $n numbers in the hash and I want to look at number $mid\n";
	my %m=();
	my $mod=$n % 2;
#	print "checking mod: n mod 2 is $mod\n";
 	if($n % 2 == 0) {
		
		$m{$mid-1}=1;
		$m{$mid}=1;
	}
	else {
		$m{$mid}=1;	
	}
	my $c=0;
	foreach my $pos (sort {$genome{$scaf}{$a}<=>$genome{$scaf}{$b}} keys %{$genome{$scaf}}) {
		$sum+=$genome{$scaf}{$pos};
#		print OUT "$scaf\t$pos\t".$genome{$scaf}{$pos}."\n";
		if(defined $m{$c}) {
			$m{$c}=$genome{$scaf}{$pos};
#			print "found one of the numbers! $c with value ".$genome{$scaf}{$pos}."\n";
		}
		$c++;
	}
	my $medsum=0;
	my $mednum=0;
	foreach my $keys (keys %m) {
		$medsum+=$m{$keys};
		$mednum++;
	}
	my $median;
	if($mednum==0) {
		print "ERROR: No median numbers for $scaf\n";
		$median="NA";
	}
	else {
		$median=$medsum/$mednum;
	}
	my $mean=$sum/$n;
	$mean = sprintf "%.1f", $mean;
	print OUT $scaf."\t".$n."\t".$median."\t".$mean."\n";
	delete $genome{$scaf};
}
close(OUT);

