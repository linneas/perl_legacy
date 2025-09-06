#!/usr/bin/perl

# # # # # #
# meanAndMedianCoverage_multPile_repeatMasked.pl
# written by Linnéa Smeds                    5 Nov 2013
# =====================================================
# Takes a fasta file with wanted sequences, a bed file
# with repeatRegions and a pileup with (several) 
# coverage column(s), and then calculates the mean and
# median coverage for each scaffold excluding the 
# repeatRegions.
#
# Output columns:
# SCAFFOLD LENGTH(NON-REP) (MEDIAN MEAN)xN
# So far used with F_and_M.pileup which gives:
#  SCAFFOLD LENGTH(NON-REP) F_MEDIAN F_MEAN M_MEDIAN M_MEAN
# =====================================================
# Usage: perl meanAndMedianCoverage_multPile_repeatMasked.pl \
#		scaffold.fa repeats.bed file.pileup \
# 		no_of_samples outfile


use strict;
use warnings;
use List::Util qw[min max];

# Input parameter
my $FASTA = $ARGV[0];
my $REPEATS = $ARGV[1];
my $PILEUP = $ARGV[2];
my $COLNO = $ARGV[3];
my $OUT = $ARGV[4];


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
				for(my $j=0; $j<$COLNO; $j++) {
					my $index=$i+3;
					$genome{$head}{$i}{$j}=0;			
				}			
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
		for(my $i=0; $i<$COLNO; $i++) {
			my $index=$i+3;
			$genome{$tab[0]}{$tab[1]}{$i}=$tab[$index];
		}
	}
}
close(PILE);

# Go through the hash
open(OUT, ">$OUT");
foreach my $scaf (keys %genome) {

	my @sumarr=("0")x$COLNO;
	my @tmparr=("0")x$COLNO;
	print "initiating sumarr @sumarr\n";
	my $n=keys %{$genome{$scaf}};
	my $mid=int($n/2);
	print "there are $n numbers in the hash and I want to look at number $mid\n";
	my %m=();
 	if($n % 2 == 0) {
		
		$m{$mid-1}=[@tmparr];
		$m{$mid}=[@tmparr];
		print "adding value ".$m{$mid}." with key $mid to hash\n";
	}
	else {
		$m{$mid}=[@tmparr];	
	}
	for (my $j=0; $j<$COLNO; $j++) {
		print "Looking at j=$j\n"; 

		my $c=0;
		foreach my $pos (sort {$genome{$scaf}{$a}{$j}<=>$genome{$scaf}{$b}{$j}} keys %{$genome{$scaf}}) {
		
			$sumarr[$j]+=$genome{$scaf}{$pos}{$j};

			if(defined $m{$c}) {
				print "inside if, before setting the hash value is ".$m{$c}[$j]." for j=$j\n"; 
				$m{$c}[$j]=$genome{$scaf}{$pos}{$j};
				print "after setting it it's ".$m{$c}[$j]."\n";
				print "found one of the numbers! $c with value ".$genome{$scaf}{$pos}{$j}."\n";
				print "adding ".$genome{$scaf}{$pos}{$j}." to ".$m{$c}[$j].", hash key is $c\n";
			}
				$c++;
		}

	}
	print "out of the for loop, check the m-hash:\n";
	for my $keys (keys %m) {
		my @a=@{$m{$keys}};
		print "key is $keys and value is:\n";
		print $a[0]." ".$a[1] ."\n";
	}

	if($n==0) {
		print "ERROR: $scaf has zero non-repeat length! Skipping line...\n";
	}
	else {
		print OUT $scaf."\t".$n;
		for (my $j=0; $j<$COLNO; $j++) {
			print "In for loop for printing; loop $j\n";
			my $mean=$sumarr[$j]/$n;

			my $medsum=0;
			my $mednum=0;
			foreach my $keys (keys %m) {
				print "add to medsum (hash key $keys): ".$m{$keys}[$j]."\n";
				$medsum+=$m{$keys}[$j];
				$mednum++;
			}
	 		print "medsum is now : $medsum\n";
			my $median;
			if($mednum==0) {
				print "ERROR: No median numbers for $scaf, col $j\n";
				$median="NA";
			}
			else {
				$median=$medsum/$mednum;
			}
			$mean = sprintf "%.1f", $mean;
			print OUT "\t".$median."\t".$mean;
		}
		print OUT "\n";
	}
	delete $genome{$scaf};
}
close(OUT);

