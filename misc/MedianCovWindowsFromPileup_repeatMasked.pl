#!/usr/bin/perl

# # # # # #
# MedianMeanCovWindowsFromPileup_repeatMasked.pl
# written by Linnéa Smeds                   16 Jan 2014
# A variant of covWindowsFromPileup_repeatMasked.pl,
# but which print only the meadian and mean coverage 
# per window and skip GC, repeats and Ns.
# (median is caculated from all non- N and repeats, 
# even if not listed in the pileup).
# THIS VERSION WORKS EVEN IF REPEATS ARE NOT MARKED IN
# THE PILEUP FILE (= ONLY CAPITAL LETTERS IN PILEUP)
# =====================================================
# Takes an assembly fasta file and check the median cov
# for each window.
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
my $windowOut = $prefix."_median.".$windowsize.".cov";
my $sumOut = $prefix."_median.summary.cov";
open(OUT, ">$windowOut");
open(SUM, ">$sumOut");
print OUT "SEQ\tWSTART\tWEND\tMEDIANCOV\tMEANCOV\n";
print SUM "SEQ\tLENGTH\tMEDIANCOV\tMEANCOV\n";

# Ge through the fasta file
my %scaffolds = ();
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
		$scaffolds{$scaffold}{'len'}=length($seq);

		my $cnt=1;
		my @tempseq=split(//, $seq);
		while(scalar(@tempseq)>0) {
			my $base = shift(@tempseq);
			unless($base =~ m/[atcgnN]/) {
				$scaffolds{$scaffold}{'cov'}{$cnt}=0;	
			}
			$cnt++;
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

while(<IN>)  {
	my @line = split(/\s+/, $_);
	if(defined($scaffolds{$line[0]}{'cov'}{$line[1]})) {
		$scaffolds{$line[0]}{'cov'}{$line[1]}=$line[3];
	}
}
close(IN);


# Go through all scaffolds and windows
foreach my $scaf (keys %scaffolds) {
	my @bigarr = ();
	my ($bigsum, $bignum) = (0,0);
#	my $size = keys %{$scaffolds{$scaf}{'cov'}};
#	print "looking at $scaf, having $size defined values\n"; 
	for(my $i=1; $i<$scaffolds{$scaf}{'len'}; $i+=$windowsize) {
		my $end = min($i+$windowsize-1, $scaffolds{$scaf}{'len'});
		my @windarr=();
		my ($windsum, $windnum) = (0,0);
		for (my $j=$i; $j<=$end; $j++) {
			if(defined($scaffolds{$scaf}{'cov'}{$j})) {
				push @windarr, $scaffolds{$scaf}{'cov'}{$j};
				push @bigarr, $scaffolds{$scaf}{'cov'}{$j};
				$windsum+=$scaffolds{$scaf}{'cov'}{$j};
				$windnum++;
				delete $scaffolds{$scaf}{'cov'}{$j};
			}
		}
		my @sortwind = sort {$a <=> $b} @windarr;
		@windarr=();
		my $median = "noBases";
		my $mean= "noBases";
		my $len=scalar(@sortwind);
		if ($len>0) {
			if($len % 2) { #Odd
#				my $temp=int($len/2);
#				print "There are $len numbers in array, hence ODD, and checking out pos $temp\n";
				$median=$sortwind[int($len/2)];
			}
			else {
#				my $temp=int($len/2);
#				print "There are $len numbers in array, hence EVEN, and checking out pos $temp and $temp-1\n";
				$median=($sortwind[int($len/2)-1]+$sortwind[int($len/2)])/2;
			}
			$mean=$windsum/$windnum;
		}
		$bigsum+=$windsum;
		$bignum+=$windnum;
		print OUT $scaf."\t".$i."\t".$end."\t".$median."\t".$mean."\n";
		@sortwind=();
	}
	my @sortbig = sort {$a <=> $b} @bigarr;
	@bigarr=();
	my $totmean="noBases";
	my $totmedian="noBases";
	my $len=scalar(@sortbig);
  	if($len>0) {
		if($len % 2) { #Odd
#			my $temp=int($len/2);
#			print "There are $len numbers in big array, hence ODD, and checking out pos $temp\n";
			$totmedian=$sortbig[int($len/2)];
		}
		else {
#			my $temp=int($len/2);
#			print "There are $len numbers in array, hence EVEN, and checking out pos $temp and $temp-1\n";
			$totmedian=($sortbig[int($len/2)-1]+$sortbig[int($len/2)])/2;
		}
		$totmean=$bigsum/$bignum;
	}

	print SUM  $scaf."\t".$scaffolds{$scaf}{'len'}."\t".$totmedian."\t".$totmean."\n";
	delete $scaffolds{$scaf};
}


