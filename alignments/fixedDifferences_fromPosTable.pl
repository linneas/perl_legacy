#!/usr/bin/perl

# fixedDifferences_fromPosTable.pl
# written by Linnéa Smeds                        13 Aug 2014
# ==========================================================
# goes through all positions in a table (with scaffold name,
# position and bases for each individual) and compares two
# species (in given columns) to look for fixed differences.
# ==========================================================
#

use strict;
use warnings;

# Input parameters
my $TABLE = $ARGV[0];
my $SP1 = $ARGV[1];	#First species columns (in real numbers)
my $SP2 = $ARGV[2];	#Second species columns (in real numbers)
my $NFRAC = $ARGV[3];	# Max ratio of Ns
my $OUT = $ARGV[4];	# Outfile

my $time=time;

# Get column start and stop
my ($s1, $e1) = split(/-/, $SP1);
my ($s2, $e2) = split(/-/, $SP2);
$s1--;
$e1--;
$s2--;
$e2--;

# Get number of individuals for each sp
my $spn1=$e2-$s1+1;
my $spn2=$e2-$s2+1;

# Open output
open(OUT, ">$OUT");

my $totcnt=0;
my $okcnt=0;
my $fixedcnt=0;
# Go through the table
open(IN, $TABLE);
while(<IN>) {
	unless(/^#/) {
		$totcnt++;
		my @tab=split(/\s+/, $_);

		# Save first species
		my %hash1=();
		for(my $i=$s1; $i<=$e1; $i++) {
			if(defined $hash1{$tab[$i]}) {
				$hash1{$tab[$i]}++;
			}
			else {
				$hash1{$tab[$i]}=1;
			}
		}
	
		# Go through first species
		my $cnt=0;
		my $base1="";
		my $bcnt1=0;
		my $check1="no";
		my $Ncheck="no";

		my $n1=0;
		if(defined $hash1{"N"}) {
			$n1=$hash1{"N"};
			delete $hash1{"N"};
		}

		foreach my $key (sort {$hash1{$a}<=>$hash1{$b}} keys %hash1) {
			if($cnt==0) {
				$base1=$key;
				$bcnt1=$hash1{$key};
			}
			$cnt++;
		}
		# Check that number of N isn't to high
		if($NFRAC>=($n1/($spn1))) {
			# Check that we only have one base
			if($cnt==1){
				$check1="ok";	
			}	
			$Ncheck="ok";	
		}
		else {
			next;
		}



		# Save second species
		my %hash2=();
		for(my $i=$s2; $i<=$e2; $i++) {
			if(defined $hash2{$tab[$i]}) {
				$hash2{$tab[$i]}++;
			}
			else {
				$hash2{$tab[$i]}=1;
			}
		}

		# Go through second species
		$cnt=0;
		my $base2="";
		my $bcnt2=0;
		my $check2="no";

		my $n2=0;
		if(defined $hash2{"N"}) {
			$n2=$hash2{"N"};
			delete $hash2{"N"};
		}

		foreach my $key (sort {$hash2{$a}<=>$hash2{$b}} keys %hash2) {
			if($cnt==0) {
				$base2=$key;
				$bcnt2=$hash2{$key};
			}
			$cnt++;
		}
	
		# Check that number of Ns for the second sp isn't too high
		if($NFRAC>=($n2/($spn2))) {

			# Check that there is only one value in the hash, and
			# that the base for sp1 and sp2 are different.
			if($cnt==1 && $base1 ne $base2) {
				$check2="ok";	
			}
		}
		else {
			$Ncheck="no";
			next;
		}

		# If the checks are ok, print position
		if($check2 eq "ok" && $check1 eq "ok") {
			print OUT $tab[0]."\t".$tab[1]."\t".$base1."\t".$bcnt1."\t".$base2."\t".$bcnt2."\n";				
			$fixedcnt++;
			$okcnt++;
		}
		# Else, check if position is approved (not too many Ns)
		else {
			if($Ncheck eq "ok") {
				$okcnt++;
			}
		}

		
	}
}
close(IN);
close(OUT);

$time=time-$time;
print $fixedcnt." fixed differences, among $okcnt approved bases (in a total of ".$totcnt." positions).\n";
print "Total time elapsed: $time sec\n";

