#!/usr/bin/perl

# # # # # #
# makeArtificialChromFasta.pl
# written by Linnéa Smeds                    4 April 2012
# =======================================================
# Make artificial chromosomes from a list with scaffolds,
# directions and possibly positions of subsets. A user
# defined number of Ns are printed between the scaffolds.
# =======================================================
# Usage: makeArtificialChromFasta.pl <fastafile> <list>
#				<gap size> <artificial fasta>
#
# Example: makeArtificialChromFasta.pl mySeq.fa list.txt
#					5000 artificial.fa

use strict;
use warnings;


# Input parameters
my $fasta = $ARGV[0];
my $list = $ARGV[1];
my $noNs = $ARGV[2];
my $out = $ARGV[3];

my $rowlength = 80;

# Save the desired parts in a hash table with sequence
# name and direction of scaffold (+ or minus)
my %parts = ();
open(IN, $list);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	if($tab[3] ne "+" && $tab[3] ne "-"){
		$tab[3]="+";
	}
	$parts{$tab[1]}=$tab[3];
#	print "add ".$tab[1]." to hash with value ".$tab[3]."\n";
}
close(IN);

# Go through the fasta file and find the desired parts
open(FAS, $fasta);
my %fasta = ();
while(<FAS>) {
	if(/>/) {
		chomp($_);
		my @tab = split(/\s+/, $_);
		$tab[0] =~ s/>//;

		# If the scaffold is found in the hash 
		# (and hence interesting)
		if(defined $parts{$tab[0]}) {
#			print $tab[0]." is found in the hash\n";
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

			if($parts{$tab[0]} eq "-") {
			#	my $temp = &revSeq($seq);	#before reverse($seq);
			#	$seq = $temp;
				$seq = reverse($seq);
				$seq =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
			}
			$fasta{$tab[0]}=$seq;
		}
	}
}
close(FAS);

#Go through the list again and print all scaffolds 
#for each chromosome
open(OUT, ">$out");
open(LST, $list);
while(<LST>) {
	my @tab = split(/\s+/, $_);
	my $catseq = $fasta{$tab[1]};
	my $chrom = $tab[0];

#	print "... and now line is $_";
	print "Creating artificial chromosome $chrom...\n";

	my $next = <LST>;
	my @nexttab =split(/\s+/, $next);
	while ($nexttab[0] eq $chrom) {
		chomp($next);
		$catseq .= "N"x$noNs;
		$catseq .= $fasta{$nexttab[1]};
		if(eof(LST)) {
			last;
		}	
		$next = <LST>;
#		print "now line is $next";
		@nexttab =split(/\s+/, $next);
	}
	unless(eof(LST)) {
#		print "inside unless\n";
#		print "putting back $next"; 
		seek(LST, -length($next), 1);	
	}
	

	print OUT ">".$chrom."\n";
	
	my @seqParts = split(/(.{$rowlength})/, $catseq);
	for my $seqs (@seqParts) {
		unless($seqs eq "") {
			print OUT $seqs."\n";
		}
	}
}
close(OUT);
close(IN);


sub revSeq { 
	my $DNAstring = shift;

	my $output = "";

	my @a = split(//, $DNAstring);

	for(@a) {
		$_ =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
		$output = $_ . $output;
	}

	return $output;
}



