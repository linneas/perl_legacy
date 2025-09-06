#!/usr/bin/perl

# gff2cdsfa_MYVERSION.pl
# written by Linnéa Smeds                       22 Nov 2014
# =========================================================
# Takes a GFF file and a fasta file, and concatenates the
# CDS entries from the GFF to nucleotide gene seq.
# =========================================================
#
#

use strict;
use warnings;

# Input parameters
my $GFF = $ARGV[0];
my $FASTA = $ARGV[1];

# Go through GFF
open(IN, $GFF);
my $gene="";
my $seq="";

while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	if($tab[2] eq "gene") {
#		print STDERR "DEBUG: looking at gene ".$tab[8].", while printing $gene\n";
		unless($gene eq "") {
			print ">".$gene."\n";
			print $seq;
		}
		$gene=$tab[8];
		$seq="";

	}
	else {
		if($tab[2] eq "CDS") {
			my ($scaf, $start, $stop) = ($tab[0], $tab[3], $tab[4]);
			my $temp;
			if($tab[6] eq "-") {
				$temp=`perl ~/private/scripts/fasta/extractPartOfFasta_seq2stdout.pl $FASTA $scaf $start $stop |perl ~/private/scripts/fasta/reverseComplementFileNoHeader_stdout.pl - `;
			}
			else {
				$temp=`perl ~/private/scripts/fasta/extractPartOfFasta_seq2stdout.pl $FASTA $scaf $start $stop`;

			}
			$seq.=$temp;
		}
	}
}
close(IN);
# Print the last gene
print ">".$gene."\n";
print $seq;

