#!/usr/bin/perl

# Script taken from http://www.perlmonks.org/?node_id=1049968
# and modified by LS to handle multi fasta files


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0]; 

open(IN, $fasta);
while(<IN>) {
	if($_ =~ m/^>/){
		my $head = $_;
		my $DNA = "";
	
		my $next = <IN>;
		while ($next !~ m/^>/) {
			chomp($next),
			$DNA.= $next;
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);

		my $protein='';
		my $codon;
		for(my $i=0;$i<(length($DNA)-2);$i+=3) {
			$codon=substr($DNA,$i,3);
			$protein.=&codon2aa($codon);
		}

		print $head;
		my @blocks = split(/(.{60})/i, $protein);
		foreach my $b (@blocks) {
			if($b ne "") {
				print "$b\n";
			}
		}
	}
}
close(IN);


#### 
# SUB ROUTINES
sub codon2aa{
	my($codon)=@_;
	$codon=uc $codon;
	my(%g)=('TCA'=>'S','TCC'=>'S','TCG'=>'S','TCT'=>'S','TTC'=>'F','TTT'=>'F',
	'TTA'=>'L','TTG'=>'L','TAC'=>'Y','TAT'=>'Y','TAA'=>'*','TAG'=>'*','TGC'=>'C',
	'TGT'=>'C','TGA'=>'*','TGG'=>'W','CTA'=>'L','CTC'=>'L','CTG'=>'L','CTT'=>'L',
	'CCA'=>'P','CCC'=>'P','CCG'=>'P','CCT'=>'P','CAC'=>'H','CAT'=>'H','CAA'=>'Q',
	'CAG'=>'Q','CGA'=>'R','CGC'=>'R','CGG'=>'R','CGT'=>'R','ATA'=>'I','ATC'=>'I',
	'ATT'=>'I','ATG'=>'M','ACA'=>'T','ACC'=>'T','ACG'=>'T','ACT'=>'T','AAC'=>'N',
	'AAT'=>'N','AAA'=>'K','AAG'=>'K','AGC'=>'S','AGT'=>'S','AGA'=>'R','AGG'=>'R',
	'GTA'=>'V','GTC'=>'V','GTG'=>'V','GTT'=>'V','GCA'=>'A','GCC'=>'A','GCG'=>'A',
	'GCT'=>'A','GAC'=>'D','GAT'=>'D','GAA'=>'E','GAG'=>'E','GGA'=>'G','GGC'=>'G',
	'GGG'=>'G','GGT'=>'G');
	if(exists $g{$codon}) {
		return $g{$codon};
	}
	else {
		print STDERR "Bad codon \"$codon\"!!\n";
		return "?";
	}
}

