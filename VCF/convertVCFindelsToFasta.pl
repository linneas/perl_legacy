#!/usr/bin/perl

# convertVCFtoFasta.pl  	
# written by Linnéa Smeds,                   16 May 2014
# =====================================================
# Takes a fasta file (or regions from a fasta file*) 
# and a vcf file, with indels (or SNPs) that should be
# masked with Ns. For both deletions and insertions, all
# bases in the REF columns are masked. That means, for 
# deletions, the full length of the
# deletion is masked+the base perceeding it is masked.
# For insertions, only the base for which the insertion
# is reported to start is masked (which is actually NOT
# part of the insertion itself, but it's the only way to
# display that there is something fishy going in in the
# region).
#
# *if fasta region is given, header is on the format
# >Chr:start-stop
# =====================================================
# usage perl convertVCFtoFasta.pl file.vcf file.fa >new.fa

use strict;
use warnings;

# Input parameters
my $VCFFILE = $ARGV[0];	# The vcf file with all positions
my $FASTA = $ARGV[1]; 	# Input fasta file

# Go through vcf and save positions and length in hash
# (this works best with small vcf and big fasta,
# otherwise one should do the opposite)
my %vcfpos = ();
open(IN, $VCFFILE);
while(<IN>) {
	unless(/^#/) {
		my @tab=split(/\s+/, $_);
		$vcfpos{$tab[0]}{$tab[1]}=length($tab[3]);
		}
}
close(IN);

# Go through fasta and infer changes
my $cnt=0;
open(FA, $FASTA);
while(<FA>) {
	if(/>/) {
		my $head=$_;
		chomp($head);
		
		# This part just reads in the sequence
		my $seq = "";
		my $next = <FA>;
		while ($next !~ m/^>/) {
			chomp($next);
			$seq .= $next;
			if(eof(FA)) {
				last;
			}	
			$next = <FA>;
		}
		seek(FA, -length($next), 1);

		# Check format of header! If >Chr:start-stop, set beginning of seq to start
		my ($chr, $start, $end);
		if($head =~ m/>(\w+):(\d+)-(\d+)/){
			$chr=$1;
			$start=$2;
			$end=$3;
#			print "DEBUG: chr $chr, $start-$end\n";
		}
		else {
			my @tab = split(/\s+/, $head);
			$tab[0] =~ s/>//;
			$chr=$tab[0];
			$start=1;
			$end=length($seq);
		}
		
		# Go through the vcf and change the sequence accordingly 
		my @s = split(//, $seq);
		foreach my $key (sort {$a<=>$b} keys %{$vcfpos{$chr}}) {
			if($key>=$start && $key<=$end) {
				my $pos = $key-$start;
				print STDERR "changing $chr:$key ($pos in array), ".$vcfpos{$chr}{$key}." bases to N(s)\n";
				for(my $i=$pos; $i<$pos+$vcfpos{$chr}{$key}; $i++) {
					$s[$i]="N";
					$cnt++;
				}
			}
		
		}
		
		# Print the sequence (changed or not)
		print $head."\n";
		print join("", @s)."\n";
		
		
	}
	

}

print STDERR "Translated $cnt positions\n";


