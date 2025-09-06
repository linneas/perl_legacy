#!/usr/bin/perl


# # # # # #
# repeatsInFasta.pl
# written by Linnéa Smeds                   20 June 2012
# ======================================================
# Looks at lower case masked repeats in a fasta file. 
# Returns one file with a list of all repeats, one file
# with a sumary per scaffold, and one file with the 
# repeat length distribution.
# ======================================================
# Usage: perl repeatsInFasta.pl <fasta file> <output pref>

use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $prefix = $ARGV[1]; 

# Define and open output files
my $outList = $prefix."_all_repeats.txt";
my $outSummary = $prefix."_repeat_per_scaffold.txt";
my $outDistr = $prefix."_repeat_distribution.txt";
open(LIST, ">$outList");
open(SUM, ">$outSummary");
open(DISTR, ">$outDistr");
print LIST "SCAFFOLD	START	STOP	LENGTH\n";
print SUM "SCAFFOLD	TOT.REPEAT\n";
print DISTR	"REP.LEN	NUMBER.REPEATS\n";

#Go through the fasta
my %hist = ();
open(IN, $fasta);
while(<IN>) {
	if($_ =~ m/^>/){
		my @tab = split(/\s+/, $_);
		my $head = $tab[0];
		chomp($head);
		$head =~ s/>//;
		my $seq = "";
		my $sum = 0;
	
		# concatenate all lines with sequences (for each scaf)
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

		#Find and print each repeat with start, end and size to a file	
		my @seq = split(//,$seq);
		my $reptemp = "";	
		my ($start, $end) = ("","");
		my $i=0; 		
		for($i=0; $i<scalar(@seq); $i++) {
			if($seq[$i] =~ m/[acgtn]/) {
				if($reptemp eq "") {
					$start = $i+1;
				}
				$reptemp .= $seq[$i];
			}
			else {
				if($reptemp ne "") {
					$end = $i;
					my $size = $end-$start+1;
					print LIST $head ."\t".$start."\t".$end."\t".$size."\n";
					$sum += $size;
					($reptemp,$start,$end) = ("","","");
					if(defined $hist{$size}) {
						$hist{$size}++;
					}
					else {
						$hist{$size}=1;
					}
				}
			}
		}
		#last row (if sequence ends with a repeat)
		if($reptemp ne "") {
			$end = $i;
			my $size = $end-$start+1;
			print LIST $head ."\t".$start."\t".$end."\t".$size."\n";
			$sum += $size;
			($reptemp,$start,$end) = ("","","");
			if(defined $hist{$size}) {
				$hist{$size}++;
			}
			else {
				$hist{$size}=1;
			}
		}
		# Print a summary line for each scaffold to another file
		print SUM $head."\t".$sum."\n";		
	}
}
close(IN);

# Print the distribution of repeat sizes to a third file
foreach my $key (sort {$a<=>$b} keys %hist) {
	print DISTR $key."\t".$hist{$key}."\n";
}

