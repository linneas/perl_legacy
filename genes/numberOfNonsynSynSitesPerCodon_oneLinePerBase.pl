#!/usr/bin/perl

my $usage = "
# # # # # #
# numberOfNonsynSynSitesPerCodon_oneLinePerBase.pl
# written by Linnéa Smeds                    18 May 2018
# ======================================================
# Takes a list with one row per base. Unlimited number 
# of fields, but one must contain position in codon (012)
# and one with the base.
# Only complete codons are used, and 
# ======================================================
# Usage: perl check4foldSites.pl 

";

use strict;
use warnings;
my $time = time;


# Input parameters
my $INFILE = $ARGV[0]; 
my $CODONFILE = $ARGV[1];	#number, codon, Nonsyn, syn

# Provide column information to where the data is found! 
my $codposcol=4;
my $genecol=3;
my $strandcol=5;
my $basecol=10;

# Read in the codon table and save in hash!
my %hash=();
open(IN, $CODONFILE);
while(<IN>){
	unless(/^#/) {
		my @tab = split(/\s+/, $_);
		$hash{$tab[1]}{'n'}=$tab[2];
		$hash{$tab[1]}{'s'}=$tab[3];
	}
}
close(IN);

open(IN, $INFILE);
my ($prevGene, $prevPos, $prevCodpos) = ("","");
while(<IN>) {
	my @tab = split(/\s+/, $_);
	
	if($tab[$codposcol]!=0) {
		print STDERR "WARNING! Codon does not start from 0, Skip!\n$_";
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
				seek(IN, -length($pos2), 1);	# Put back!
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
						seek(IN, -length($pos3), 1); # Put back!
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

						if(defined $hash{$codon}) {
							
							my $ns=$hash{$codon}{'n'};
							my $s=$hash{$codon}{'s'};
						
							push @tab3, $ns;
							push @tab3, $s;

							print $_;
							print $pos2;
							print join("\t", @tab3)."\n";
						}
						else {
							print "Codon $codon was not defined, skip lines!!\n";
						}
					}
				}
			}
		}
	}
}
close(IN);

 


