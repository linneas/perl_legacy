#!/usr/bin/perl

# maskBedRegionsInFasta.pl  	
# written by Linnéa Smeds,                  21 May 2014
# =====================================================
# Takes a fasta file (or regions from a fasta file*) 
# and a bed file with regions that should be masked 
# with Ns.
#
# *if fasta region is given, header is on the format
# >Chr:start-stop
# =====================================================
# usage perl maskBedRegionsInFasta.pl file.bed file.fa >new.fa

use strict;
use warnings;

# Input parameters
my $BEDFILE = $ARGV[0];	# The bed file with all regions
my $FASTA = $ARGV[1]; 	# Input fasta file

# Go through vcf and save positions and length in hash
# (this works best with small vcf and big fasta,
# otherwise one should do the opposite)
my %regions = ();
open(IN, $BEDFILE);
while(<IN>) {
	unless(/^#/) {
		my @tab=split(/\s+/, $_);
		my $start=$tab[1]+1;
		my $len=$tab[2]-$tab[1];
		$regions{$tab[0]}{$start}=$len;
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
		
		# Go through the regions and change the sequence accordingly 
		my @s = split(//, $seq);
		foreach my $key (sort {$a<=>$b} keys %{$regions{$chr}}) {
			if($key>=$start && $key<=$end) {
				my $pos = $key-$start;
				print STDERR "changing $chr:$key ($pos in array), ".$regions{$chr}{$key}." bases to N(s)\n";
				for(my $i=$pos; $i<$pos+$regions{$chr}{$key}; $i++) {
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


