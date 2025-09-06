#!/usr/bin/perl

# # # # # #
# extractPartOfFastaMult.pl
# written by Linnéa Smeds 3 Feb 2011, mod 12 Mar 2012
# ====================================================
# Extract specific regions from a fasta file, spec. in 
# a list with sequence name, start and stop. 
# Note: The sequence header must not contain spaces. If
# it does, give only the first tab, eg "contig001" if 
# header is ">contig001 chr=1 length=1000..."
# ====================================================
# Usage: extractPartOfFasta.pl <fastafile> <list>
#
# Example: extractPartOfFasta.pl mySeq.fa posList.txt >out.fa

use strict;
use warnings;


# Input parameters
my $fasta = $ARGV[0];
my $list = $ARGV[1];

my $rowlength = 80;

# Save the desired parts in a hash of hash table
# with sequence name as first key, start pos as
# second key and end pos as value.
my %parts = ();
open(IN, $list);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$parts{$tab[0]}{$tab[1]}=$tab[2];
}
close(IN);

# Go through the fasta file and find the desired parts
open(FAS, $fasta);
my ($seq, $head, $seqFlag) = ("", "", "off");
while(<FAS>) {
	if(/>/) {

		my @tab = split(/\s+/, $_);
		$tab[0] =~ s/>//;

		# If the chomo is found in the hash 
		# (and hence interesting)
		if(defined $parts{$tab[0]}) {
			my $seq = "";
			my $next = <FAS>;
			while ($next !~ m/^>/) {
				chomp($next);
				$seq .= $next;
				if(eof(FAS)) {
					last;
				}	
				$next = <FAS>;
			}
			seek(FAS, -length($next), 1);

			# If there are more than one desired region for a sequence,
			# go through all of them.
			foreach my $start (sort {$a <=> $b} keys %{$parts{$tab[0]}}) {
				my $end = $parts{$tab[0]}{$start};
				my $noOfBases = $end-$start+1;

				my $len = length($seq);
				print ">".$tab[0]." orig_len=$len, extract $start-$end ($noOfBases bp)\n";
				my $substr = substr($seq, $start-1, $noOfBases);
				my @seqParts = split(/(.{$rowlength})/, $substr);
		#		print "looking at ".$tab[0]." with seq $substr\n";
				for my $seqs (@seqParts) {
					unless($seqs eq "") {
						print $seqs."\n";
					}
				}
			}
		}
	}
}

