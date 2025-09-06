#!/usr/bin/perl

# # # # # #
# makeWindowsFileFromFasta.pl
# written by Linnéa Smeds               18 October 2012
# =====================================================
# Takes an assembly and a window size and prints a list
# of either all or only the full Size windows.
# =====================================================
# Usage: perl makeWindowsFileFromFasta.pl <fasta>
#			<window size> <all_flag> <out>
#

use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $FASTA = $ARGV[0];
my $WINDSIZE = $ARGV[1];
my $FLAG = $ARGV[2];
my $OUTPUT = $ARGV[3];

# Output files
open(OUT, ">$OUTPUT");

unless($FLAG eq "all" || $FLAG eq "full") {
	die "Third input must be \"all\" or \"full\"!\n";
}

my %windows = ();
# Ge through the fasta file
open(SEQ, $FASTA);
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

		my $totcnt = 0;
		my $i;

		for($i=1; $i<length($seq); $i+=$WINDSIZE) {
			my $end = min($i+$WINDSIZE-1, length($seq));
			unless($FLAG eq "full" && $end-$i+1<$WINDSIZE) {
				print OUT $scaffold."\t".$i."\t".$end."\n";
			}
		}
	}
}
close(SEQ);
close(OUT);


