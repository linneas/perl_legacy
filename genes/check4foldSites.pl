#!/usr/bin/perl

my $usage = "
# # # # # #
# check4foldSites.pl
# written by Linnéa Smeds                  19 March 2018
# ======================================================
# Takes a combined bed/vcf which contains information on
# both pos in codon, strand and base. NOTE that the pos
# should already be ordered from start_codon to stop, and
# IF the strand is \"-\", the script will complement the
# base to the other strand (but NOT reverse it, since 
# the order is already correct!)
# ======================================================
# Usage: perl check4foldSites.pl 

";

use strict;
use warnings;

# Input parameters
my $INFILE = $ARGV[0]; 

# Provide column information to where the data is found! 
my $codposcol=4;
my $genecol=3;
my $strandcol=5;
my $basecol=10;


my $time = time;

# Hash with all amino_acids
my %convertor = (
    'TCA' => 'S', 'TCC' => 'S', 'TCG' => 'S','TCT' => 'S',    # Serine
    'TTC' => 'F', 'TTT' => 'F',    # Phenylalanine
    'TTA' => 'L', 'TTG' => 'L',    # Leucine
    'TAC' => 'Y', 'TAT' => 'Y',    # Tyrosine
    'TAA' => '*', 'TAG' => '*',    # Stop
    'TGC' => 'C', 'TGT' => 'C',    # Cysteine
    'TGA' => '*',    # Stop
    'TGG' => 'W',    # Tryptophan
    'CTA' => 'L', 'CTC' => 'L', 'CTG' => 'L', 'CTT' => 'L',    # Leucine
    'CCA' => 'P', 'CCC' => 'P', 'CCG' => 'P', 'CCT' => 'P',    # Proline
    'CAC' => 'H', 'CAT' => 'H',    # Histidine
    'CAA' => 'Q', 'CAG' => 'Q',    # Glutamine
    'CGA' => 'R', 'CGC' => 'R', 'CGG' => 'R', 'CGT' => 'R',    # Arginine
    'ATA' => 'I', 'ATC' => 'I', 'ATT' => 'I',    # Isoleucine
    'ATG' => 'M',    # Methionine
    'ACA' => 'T', 'ACC' => 'T',  'ACG' => 'T', 'ACT' => 'T',    # Threonine
    'AAC' => 'N', 'AAT' => 'N',    # Asparagine
    'AAA' => 'K', 'AAG' => 'K',    # Lysine
    'AGC' => 'S', 'AGT' => 'S',    # Serine
    'AGA' => 'R', 'AGG' => 'R',    # Arginine
    'GTA' => 'V',  'GTC' => 'V', 'GTG' => 'V', 'GTT' => 'V',    # Valine
    'GCA' => 'A', 'GCC' => 'A', 'GCG' => 'A', 'GCT' => 'A',    # Alanine
    'GAC' => 'D', 'GAT' => 'D',    # Aspartic Acid
    'GAA' => 'E', 'GAG' => 'E',    # Glutamic Acid
    'GGA' => 'G', 'GGC' => 'G', 'GGG' => 'G', 'GGT' => 'G',    # Glycine
    );

# Hash with start of 4fold site codons
my %FFstart = (
	'CT' => 'S',
	'GT' => 'S', 
	'TC' => 'S',
	'CC' => 'S',
	'AC' => 'S',
	'GC' => 'S',
	'CG' => 'S',
	'GG' => 'S'
	);


open(IN, $INFILE);
my ($prevGene, $prevCodpos) = ("","");
while(<IN>) {
	my @tab = split(/\s+/, $_);
	
	if($tab[$codposcol]!=0) {
		print STDERR "WARNING! Codon does not start from 0!\n$_";
	}
	else {
		if(eof(IN)) {
			print STDERR "WARNING: Last line, can't check full codon \n$_";
			last;
		}
		my $pos2=<IN>;
		my @tab2=split(/\s+/,$pos2);
		my $pos3;
		my @tab3;
		if($tab2[$genecol] ne $tab[$genecol]) {	
		#next line doesn't belong to same gene, put back!
			print STDERR "WARNING: the following codon was unfinished and not printed: \n$_";
			seek(IN, -length($pos2), 1);
			next;
			
		}
		else {
			if($tab2[$codposcol]!=1) {
				print STDERR "WARNING! Pos 0 is not followed by 1!\n$pos2";
			}
			else {
				if(eof(IN)) {
					print STDERR "VARNING: Last line, can't check full codon \n$_"."$pos2";
					last;
				}
				$pos3=<IN>;
				@tab3=split(/\s+/,$pos3);
				if($tab3[$genecol] ne $tab[$genecol]) {	
					#next line doesn't belong to same gene, put back!
					print STDERR "WARNING: the following codon was unfinished and not printed: \n$_"."$pos2";
					seek(IN, -length($pos3), 1);
					next;
				}
				else {
					if($tab3[$codposcol]!=2) {
						print STDERR "WARNING! Pos 1 is not followed by 2!\n$pos3";
					}
					else {
						# Data is fine! Extract codon (first take complement if needed)
						my $codon="";
	#					print STDERR "our bases are ".$tab[$basecol]." ". $tab2[$basecol]." ".$tab3[$basecol]."\n";
						if($tab[$strandcol] eq "-") {
							my $tmp=$tab[$basecol];
							$tmp  =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
							$codon.= $tmp;
						}
						else {
							$codon.= $tab[$basecol];
						}
						if($tab2[$strandcol] eq "-") {
							my $tmp=$tab2[$basecol];
							$tmp  =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
							$codon.= $tmp;
						}
						else {
							$codon.= $tab2[$basecol];
						}
						if($tab3[$strandcol] eq "-") {
							my $tmp=$tab3[$basecol];
							$tmp  =~ tr/[A,T,C,G,a,t,c,g]/[T,A,G,C,t,a,g,c]/;
							$codon.= $tmp;
						}
						else {
							$codon.= $tab3[$basecol];
						}

						my $start=substr($codon, 0, 2);
	#					print STDERR "DEBUG: Looking at codon $codon!\n";
						
						if (defined $FFstart{$start}) {
	#						print STDERR "DEBUG: Codon $codon has a synonymous start $start\n";
							push @tab3, "S";
						}
						print $_;
						print $pos2;
						print join("\t", @tab3)."\n";
					}
				}
			}
		}
	}
}
close(IN);

 


