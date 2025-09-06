#!/usr/bin/perl

# gff2cdsfa.withTranscripts.pl
# written by Linnéa Smeds                        8 Jan 2018
# update of gff2cdsfa_MYVERSION.pl, but now using bedtools
# for extracting the sequence, and also printing all possible
# transcripts for each gene.
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

# Other parameters
my $bpPerRow=80;

# Go through GFF
open(IN, $GFF);
my $transc="";
my $seq="";

while(<IN>) {
	chomp($_);
	my @tab = split(/\t/, $_);
	if($tab[2] eq "transcript") {
		unless($transc eq "") {
			print ">".$transc."\n";
 			my @blocks = split(/(.{$bpPerRow})/i, $seq);
			foreach my $b (@blocks) {
				if($b ne "") {
					print "$b\n";
				}
			}
		}
		# Find transcript name:
		my @temp=split(/;/, $tab[8]);
		my $setflag=0;
		foreach my $string (@temp){
			if($string =~ m/transcript_id/) {
#				print "DEBUG: String is $string\n";
				my @tmp=split(/\"/, $string);
				$transc=$tmp[1];
				$setflag=1;
#				print "DEBUG: Found transcript $transc\n";
			}
		}
		if($setflag==0) {
			die "No transcript_id given found on line $_\n";
		}
		$seq="";

	}
	if($tab[2] eq "CDS") {
		my ($scaf, $start, $stop) = ($tab[0], $tab[3], $tab[4]);
		my $temp;
		if($tab[6] eq "-") {
			$temp=`perl ~/private/scripts/fasta/extractPartOfFasta_seq2stdout.pl $FASTA $scaf $start $stop |perl ~/private/scripts/fasta/reverseComplementFileNoHeader_stdout.pl - `;
		}
		else {
			$temp=`perl ~/private/scripts/fasta/extractPartOfFasta_seq2stdout.pl $FASTA $scaf $start $stop`;

		}
		$temp=~s/\n//g;
		$seq.=$temp;
	}
}
close(IN);
# Print the last gene
print ">".$transc."\n";
my @blocks = split(/(.{$bpPerRow})/i, $seq);
foreach my $b (@blocks) {
	if($b ne "") {
		print "$b\n";
	}
}

