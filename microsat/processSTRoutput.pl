#!/usr/bin/perl

# processSTRoutput.pl  	
# written by Linnéa Smeds,                   9 Mar 2017
# =====================================================
# Takes the output from the first step of STR-FM:
# *A .TR file with a list of all microsatellites in the
# reference (per chromosome or full genome) 
# *An RF.j file with a list of all reads containing 
# microsatellites, and their location. 
# Produces:.............
#
# Note that STR-FM only handles one type of repeats
# (mono, di, tri, tetra) at the time, but there is 
# nothing that prevents this script to be used on a 
# merged result (as long as the reference and the reads
# contain the same microsatellites).
# =====================================================
# usage: perl processSTRoutput.pl  	

use strict;
use warnings;
my $time=time;


# Input parameters
my $TR = $ARGV[0];	# Six columns: chr start, stop, motif, totlen, motiflen
my $RFJ = $ARGV[1];	# 18 Columns: Len, l_flanklen, r_flanklen, motif, hammingdist,
					# readname, seq, qual, readname, chr, l_flank_st, l_flank_end,
					# tr_st, tr_end, r_flank_st, r_flank_end, len, tr_ref_seq 
my $OUT = $ARGV[2];


# Open outfile handle
open(OUT, ">$OUT");

# Since both files are sorted after coordinates I thought we could go through
# both files simultaneously, but the read file is sorted after start of left 
# flank, which means motif close enough to eachother might have intermingled
# reads (=> if looking at motif A, we would discard reads from motif B, and 
# when we look at motif B those reads are already processed) 
# Therefore it's better to save the reference in a hash:

print STDERR "Saving TR elements in reference...\n";
my %hash = ();
my $cnt=0;
open(IN, $TR);
while(<IN>) {
	chomp($_);
	my ($chr, $start, $end, $mot, $len, $mlen) = split(/\s+/, $_); 
	$hash{$chr}{$start}{'end'}=$end;
	$hash{$chr}{$start}{'motif'}=$mot;
	$hash{$chr}{$start}{'len'}=$len;
	$cnt++;
}
close(IN);
print STDERR "...saved $cnt elements.\n";


# Go through the reads, add them to the hash!
print STDERR "Go through the reads, assigning them to the TR elements...\n";
open(RFJ, $RFJ);
$cnt=0;
my $usedcnt=0;
while(<RFJ>) {
#	print "Line is $_\n";
	my @tab = split(/\s+/, $_);
	my $chr=$tab[9];
	my $start=$tab[12];
	my $motif=$tab[3];
	my $len = $tab[0];
#	print "chrom is $chr\n";

	if(defined $hash{$chr}{$start} && $hash{$chr}{$start}{'motif'} eq $motif) {
		if(exists $hash{$chr}{$start}{'cnt'}{$len}) {
			$hash{$chr}{$start}{'cnt'}{$len}++;
		}
		else {		
			$hash{$chr}{$start}{'cnt'}{$len}=1;
		}
		$usedcnt++;
	}
	$cnt++
}
close(RFJ);
print STDERR "...processed $cnt reads ($usedcnt was assigned to TR elements)\n";


# And finally, go through the reference again and look at read counts for
# different lengths!
print STDERR "Print results...\n";
foreach my $chr (keys %hash) {
	foreach my $start (sort {$a<=>$b} keys %{$hash{$chr}}) {
		
		#go through the read-counts if there are any!
		my $counts="";
		my $sum=0;
		my $typecnt=0;
		if(exists $hash{$chr}{$start}{'cnt'}) {
			foreach my $l (sort {$hash{$chr}{$start}{'cnt'}{$b}<=>$hash{$chr}{$start}{'cnt'}{$a}} keys %{$hash{$chr}{$start}{'cnt'}}) {
				$counts.=$l."(".$hash{$chr}{$start}{'cnt'}{$l}.")-";
				$sum+=$hash{$chr}{$start}{'cnt'}{$l};
				$typecnt++;
			}
		}
		$counts =~ s/\)-$/\)/;

		print OUT $chr."\t".$start."\t".$hash{$chr}{$start}{'motif'}."\t".$hash{$chr}{$start}{'len'}."\t".$sum."\t".$counts."\t".$typecnt."\n";
	}
}
print STDERR "...Done!\n";

$time=time-$time;
print STDERR "Total time elapsed: $time sec\n";
