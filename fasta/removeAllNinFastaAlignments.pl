#!/usr/bin/perl

# # # # # #
# removeAllNinFastaAlignments.pl
# written by Linnéa Smeds             13 November 2014
# ====================================================
# Takes a fasta alignment file, goes through all pos
# and remove any position where all samples have "N".
# ====================================================
# Usage: perl removeAllNinFastaAlignments.pl <FASTA IN> <FASTA OUT>
# Example perl removeAllNinFastaAlignments.pl alignment.fa alignment_noAllN.fa

use strict;
use warnings;


# Input parameters
my $FASTA = $ARGV[0];
my $OUT = $ARGV[1];

# First needs to go through all sequences to check for allN positions
open(FAS, $FASTA);
my %Npositions = ();
my $cnt=0;
while(<FAS>) {
	if(/>/) {
		my @tab = split(/\s+/, $_);
		my $seq = "";

		my $next = <FAS>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(FAS)) {
				last;
			}	
			$next = <FAS>;
		}
		seek(FAS, -length($next), 1);
	
		my @bases = split(//, $seq);

		# First sequence, save all N-positions.
		if($cnt == 0) {
			for (my $i=0; $i<scalar(@bases); $i++) {
				if($bases[$i] eq "N" || $bases[$i] eq "n") {
					$Npositions{$i}=1;
				}
			}
			my $size = keys %Npositions;
			print "Checked the first sequence, found $size N positions\n";
		}
		# All other sequences, just look at the ones that are already N!
		else{
			foreach my $key (keys %Npositions) {
				unless($bases[$key] eq"N" || $bases[$key] eq "n") {
					delete $Npositions{$key};
				}
			}
		}
		$cnt++;
	}
}
close(FAS);

my $size = keys %Npositions;
print "Found $size all-N positions!\n";

# Now, go through the sequence again, removing all the Ns
# And print to outfile
open(OUT, ">$OUT");
open(FAS, $FASTA);
while(<FAS>) {
	if(/>/) {
		my @tab = split(/\s+/, $_);
		my $seq = "";

		my $next = <FAS>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(FAS)) {
				last;
			}	
			$next = <FAS>;
		}
		seek(FAS, -length($next), 1);
	
		my @bases = split(//, $seq);

		# Remove all saved positions
		foreach my $key (keys %Npositions) {
			$bases[$key]="";
		}
		print OUT $_;
		print OUT join("", @bases)."\n";
	}
}
close(FAS);








