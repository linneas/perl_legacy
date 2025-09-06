#!/usr/bin/perl

# convertVCFtoFasta.pl  	
# written by Linnéa Smeds,                   16 May 2014
# =====================================================
# Takes a fasta file (or regions from a fasta file*) 
# and a vcf file, and incorporates all the varying sites
# as IUPAC code in the fasta sequence (no matter what
# genotype the different samples have).
# Note! CANNOT handle indels, ONLY varying sites!
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

# Make hash to save the IUPAC code!
my %iupac = ("A,C" => "M",
"A,G" => "R",
"A,T" => "W",
"C,G" => "S",
"C,T" => "Y",
"G,T" => "K",
"A,C,G" => "V",
"A,C,T" => "H",
"A,G,T" => "D",
"C,G,T" => "B",
"A,C,G,T" => "N");


# Go through vcf and save positions in hash
# (this works best with small vcf and big fasta,
# otherwise one should do the opposite)
my %vcfpos = ();
open(IN, $VCFFILE);
while(<IN>) {
	unless(/^#/) {
		my @tab=split(/\s+/, $_);

		my @bases = split(/,/, $tab[4]);
		push @bases, $tab[3];
		my $val=join(",", sort(@bases));

		# This is a "hash-of-hash", chrom=main key, pos=secondary key, all bases (ref+alt)=value
		$vcfpos{$tab[0]}{$tab[1]}=$val;
#		print "DEBUG: Add $val for ".$tab[0].":".$tab[1]."\n";
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
				print STDERR "changing $chr:$key ($pos in array) from ".$s[$pos]."\t";
				$s[$pos]=$iupac{$vcfpos{$chr}{$key}};
				print STDERR "New base: ".$s[$pos]."\n";
				$cnt++;
			}
		
		}
		
		# Print the sequence (changed or not)
		print $head."\n";
		print join("", @s)."\n";
		
		
	}
	

}

print STDERR "Translated $cnt positions\n";


