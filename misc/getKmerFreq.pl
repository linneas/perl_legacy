#!/usr/bin/perl

# getKmerFreq.pl
# written by Linnéa Smeds                        Sept 2011
# ========================================================
#
# ========================================================
# usage perl 

use strict;
use warnings;

my $type = $ARGV[0];
my $in = $ARGV[1];
my $kmersize = $ARGV[2];
my $out = $ARGV[3];

my %kmers = ();
open(IN, $in);

if($type eq "fastq"){
	while(<IN>) {
		if(/^@/) {
			my $seq = <IN>;
			chomp($seq);
			my $plus = <IN>;
			my $qual = <IN>;
			
			my $start=0;
			while($start<=length($seq)-$kmersize) {
				my $kmer = substr($seq, $start, $kmersize);
				if(defined $kmers{$kmer}) {
					$kmers{$kmer}++;
				}
				else {
					$kmers{$kmer}=1;
				}
				$start++;
			}
		}
	}
	close(IN);
}
elsif($type eq "fasta"){
	while(<IN>) {
		if(/^>/) {
			my $seq = "";
			my $next = <IN>;
			while ($next !~ m/^>/) {
				chomp($next),
				$seq.= $next;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
			}
			seek(IN, -length($next), 1);

			my $start=0;
			while($start<=length($seq)-$kmersize) {
				my $kmer = substr($seq, $start, $kmersize);
				if(defined $kmers{$kmer}) {
					$kmers{$kmer}++;
				}
				else {
					$kmers{$kmer}=1;
				}
				$start++;
			}
		}
	}
	close(IN);
}
else {
	die "Unrecognized type: $type. Try \"fasta\" or \"fastq\" instead.\n";
}

my %depth=();
foreach my $key (keys %kmers) {
	if(defined $depth{$kmers{$key}}) {
		$depth{$kmers{$key}}++;
	}
	else {
		$depth{$kmers{$key}}++;
	}
}

open(OUT, ">$out");
foreach my $key (sort {$a<=>$b} keys %depth) {
	print OUT $key."\t".$depth{$key}."\n";
}

