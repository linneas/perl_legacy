#!/usr/bin/perl

# # # # # # 
# closeToEndsSummary.pl               
# written by Linnéa Smeds                       22 May 2012
# =========================================================
# 
# =========================================================
# usage perl 

use strict;
use warnings;

my $time = time;

my $fasta = $ARGV[0];
my $listOfScaffolds = $ARGV[1];
my $binSize = $ARGV[2];
my $endThres = $ARGV[3];
my $prefix = $ARGV[4];

# Save all wanted sequence names
my %wanted = ();
open(IN, $listOfScaffolds);
while(<IN>) {
	chomp($_);
	$wanted{$_}=1;
}
close(IN);


#Output files:
my $firstGC = $prefix."_GC_in_start_".$binSize."bpBins.txt";
my $lastGC = $prefix."_GC_in_end_".$binSize."bpBins.txt";
my $firstRep = $prefix."_repeat_in_start_".$binSize."bpBins.txt";
my $lastRep = $prefix."_repeat_in_end_".$binSize."bpBins.txt";
my $firstNs = $prefix."_Ns_in_start_".$binSize."bpBins.txt";
my $lastNs = $prefix."_Ns_in_end_".$binSize."bpBins.txt";

#Make hashes for each type
my %fGC = ();
my %lGC = ();
my %fRep = ();
my %lRep = ();
my %fNs = ();
my %lNs = ();

#Go through the fasta file
open(IN, $fasta);
while(<IN>) {
	if(/^>/) {
		my $head = $_;
		chomp($head);
		$head =~ s/>//;
		
		if(defined $wanted{$head}) {
	
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

			#Finding the beginning and end of the sequence:
			my $first =substr($seq, 0, $endThres);
			my $last = substr($seq, length($seq)-$endThres, $endThres);
			$last=reverse($last);

#			print "Start:" . $first ."\n";
#			print "End:" . $last ."\n";

			# Looking at the left side
			for (my $i=0; $i<$endThres; $i+=$binSize) {
#				print "LEFT: looking a bin starting with $i and ending with $i+$binSize\n";
				my $temp = substr($first, 0, $binSize);

				my ($reps, $GC, $Ns) = (0,0,0);				

				my @bases = split(//, $temp);
				foreach my $b (@bases) {
					if($b=~ m/N/i) {
						$Ns++;
					}
					if($b=~ m/[atcgn]/) {
						$reps++;
					}
					if($b=~ m/[GC]/i) {
						 $GC++;
					}
				}
				$Ns=sprintf "%.2f", $Ns/scalar(@bases);
				$reps=sprintf "%.2f", $reps/scalar(@bases);
				$GC=sprintf "%.2f", $GC/scalar(@bases);
			
				$fGC{$head}{$i}=$GC;
				$fRep{$head}{$i}=$reps;
				$fNs{$head}{$i}=$Ns;
				
				$first = substr($first, $binSize, length($first)-$binSize);
			}


			# Looking at the right side
			for (my $i=0; $i<$endThres; $i+=$binSize) {
#				print "RIGHT: looking a bin starting with $i and ending with $i+$binSize\n";
				my $temp = substr($last, 0, $binSize);

				my ($reps, $GC, $Ns) = (0,0,0);				

				my @bases = split(//, $temp);
				foreach my $b (@bases) {
					if($b=~ m/N/i) {
						$Ns++;
					}
					if($b=~ m/[atcgn]/) {
						$reps++;
					}
					if($b=~ m/[GC]/i) {
						 $GC++;
					}
				}
				$Ns=sprintf "%.2f", $Ns/scalar(@bases);
				$reps=sprintf "%.2f", $reps/scalar(@bases);
				$GC=sprintf "%.2f", $GC/scalar(@bases);

				$lGC{$head}{$i}=$GC;
				$lRep{$head}{$i}=$reps;
				$lNs{$head}{$i}=$Ns;
				
				$last = substr($last, $binSize, length($last)-$binSize);
			}
	
		}
	}		
}
close(IN);


#Open and print to output files
open(OUT1, ">$firstGC");
open(OUT2, ">$lastGC");
open(OUT3, ">$firstRep");
open(OUT4, ">$lastRep");
open(OUT5, ">$firstNs");
open(OUT6, ">$lastNs");

print OUT1 "DIST2END";
print OUT2 "DIST2END";
print OUT3 "DIST2END";
print OUT4 "DIST2END";
print OUT5 "DIST2END";
print OUT6 "DIST2END";

foreach my $key (sort keys %fGC) {
	print OUT1 "\t".$key;
	print OUT2 "\t".$key;
	print OUT3 "\t".$key;
	print OUT4 "\t".$key;
	print OUT5 "\t".$key;
	print OUT6 "\t".$key;
}

print OUT1 "\n";
print OUT2 "\n";
print OUT3 "\n";
print OUT4 "\n";
print OUT5 "\n";
print OUT6 "\n";


for (my $i=0; $i<$endThres; $i+=$binSize) {
	
	print OUT1 $i;
	print OUT2 $i;
	print OUT3 $i;
	print OUT4 $i;
	print OUT5 $i;
	print OUT6 $i;

	foreach my $key (sort keys %fGC) {
		print OUT1 "\t".$fGC{$key}{$i};
		print OUT2 "\t".$lGC{$key}{$i};
		print OUT3 "\t".$fRep{$key}{$i};
		print OUT4 "\t".$lRep{$key}{$i};
		print OUT5 "\t".$fNs{$key}{$i};
		print OUT6 "\t".$lNs{$key}{$i};
	}
	print OUT1 "\n";
	print OUT2 "\n";
	print OUT3 "\n";
	print OUT4 "\n";
	print OUT5 "\n";
	print OUT6 "\n";

}


$time = time - $time;
print "Time elapsed: $time sec.\n";
