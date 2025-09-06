#!/usr/bin/perl

# # # # # #
# CheckOverlaps.pl
# written by Linnéa Smeds June 2010, mod May 2011
# ===================================================
# Description:
# Takes a fasta file on the form 
#
# 	>gene|transcript|chrom|start|stop|(length if included)
#	NUCLEOTIDESEQUENCE				
# 	>.. (etc)
#  	
# and removes genes that overlap. Several overlaping 
# transcripts from the same gene is considered OK.
#
# ===================================================
# Usage: perl CheckOverlaps.pl inputfile outputfile
# ===================================================

use strict;
use warnings;

my $time = time;

#Parameters
my $target = $ARGV[0];
my $output = $ARGV[1];

open(IN, $target);
open(OUT, ">$output");

my %seq = ();

while(<IN>) {
	my $head = $_;
	chomp($head);
	my $seqnce = "";
	
	my $next = <IN>;
	while ($next !~ m/^>/) {
		chomp($next),
		$seqnce.= $next;
		if(eof(IN)) {
			last;
		}	
		$next = <IN>;
	}
	seek(IN, -length($next), 1);


	my @a = split(/\|/, $head);
	my $overlapFlag = "off";
	foreach my $key (keys %seq) {
		my @t = split(/\|/, $key);
		unless ($a[0] eq $t[0]) {
			if($a[2] eq $seq{$key}{'chrom'}) {
				if (($a[3]>=$seq{$key}{'start'} && $a[3]<=$seq{$key}{'end'}) ||
					($a[4]>=$seq{$key}{'start'} && $a[4]<=$seq{$key}{'end'}) ||
					($seq{$key}{'start'}>=$a[3] && $seq{$key}{'start'}<=$a[4]) ||
					($seq{$key}{'end'}>=$a[3] && $seq{$key}{'end'}<=$a[4])) {
						$seq{$key}{'over'} = "yes";
						$overlapFlag="on";
				}
			}
		}
	}
	my $key = $a[0]."|".$a[1];
	$seq{$key}{'chrom'} = $a[2];
	$seq{$key}{'start'} = $a[3];
	$seq{$key}{'end'} = $a[4];
	if(defined $a[5]) {
		$seq{$key}{'len'} = $a[5];
	}
	else {
		$seq{$key}{'len'} = "";
	} 
	if($overlapFlag eq "off") {
		$seq{$key}{'over'} = "off";
		$seq{$key}{'seq'} = $seqnce;
	}
	else {
		$seq{$key}{'over'} = "on";
	}
}
			
foreach my $key (sort keys %seq) {
	if($seq{$key}{'over'} eq "off") {
		print OUT $key ."|". $seq{$key}{'chrom'} ."|". $seq{$key}{'start'} ."|". $seq{$key}{'end'} .
			"|".$seq{$key}{'len'}."\n".$seq{$key}{'seq'}."\n";
		#print OUT $key."\n".$seq{$key}{'seq'};  #Only gene and transcript number as header
	}
}

$time = time - $time;
print "Total time elapsed: $time s\n";

