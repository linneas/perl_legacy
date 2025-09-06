#!/usr/bin/perl

# checkMultHits.pl
# written by Linnéa Smeds                        4 Nov 2011
# =========================================================
# 
# =========================================================
#
#

use strict;
use warnings;

# Input parameters
my $MultGFF = $ARGV[0];
my $outpref = $ARGV[1];

my %genes = ();
my %nonOvl = ();

open(IN, $MultGFF);
while(<IN>) {
	if(/similarity/) {
		my @tab = split(/\t/, $_);
		my @last = split(/\s;\s/, $tab[8]);
#		print "splitting ".$tab[8]."\n";

		$last[1] =~ m/Query (\w+)/;
		my $gene = $1;
#		print "looking at gene $gene\n";
		my $id = $tab[0]."_".$tab[3]."_".$tab[4];
		my $ovlFlag = "off";

		# Checking if the gene is already in the hash:
		if(defined $genes{$gene}) { 
#			print "gene $gene is already defined\n";
			foreach my $a (@last) {
				if($a =~ m/Align/){
	#				print "looking at $a\n";
					my @b = split(/\s+/, $a);
					my $start = $b[2];
					my $end = $b[2]+$b[3]-1;

					foreach my $key (keys %{$genes{$gene}{'exon'}}) {
		
	#					print "Comparing with  $key ".$genes{$gene}{'exon'}{$key}{'start'}."-".$genes{$gene}{'exon'}{$key}{'end'}."\n";
						if ($end >= $genes{$gene}{'exon'}{$key}{'start'} && $start<=$genes{$gene}{'exon'}{$key}{'end'}) {
#							print "OVERLAP: looking at $gene $id $start-$end and found overlap with $key\n";
							$ovlFlag = "on";
						}
					
					}
				}
			}

			# If any of the exons overlapped
			if($ovlFlag eq "on") {
#				print "Comparing the scores: The saved gene has score ".$genes{$gene}{'score'}." and this one has ".$tab[5]."\n";
				if($genes{$gene}{'score'}<$tab[5]) {
#					print "replacing $gene from ".$genes{$gene}{'id'}." with $id\n";
					delete $genes{$gene};
					$genes{$gene}{'id'}=$id;
					$genes{$gene}{'score'}=$tab[5];
					my $cnt=1;
					foreach my $a (@last) {
						if($a =~ m/Align/){
							my $exon = "exon_".$cnt;
							my @b = split(/\s+/, $a);
							$genes{$gene}{'exon'}{$exon}{'start'}=$b[2];
							$genes{$gene}{'exon'}{$exon}{'end'}=$b[2]+$b[3]-1;
							$cnt++;
						}
					}
				}
			}
			else {
#				print "$gene has two hits that don't overlap at all\n";
				$nonOvl{$gene}=1;
			}

		}
		# If not - save it!
		else {
			my $cnt=1;
			$genes{$gene}{'score'} = $tab[5];
			$genes{$gene}{'id'} = $id;
			foreach my $a (@last) {
				if($a =~ m/Align/){
					my $exon = "exon_".$cnt;
					my @b = split(/\s+/, $a);
					$genes{$gene}{'exon'}{$exon}{'start'}=$b[2];
					$genes{$gene}{'exon'}{$exon}{'end'}=$b[2]+$b[3]-1;
					$cnt++;
				}
			}
		}
	}
}
close(IN);

# Print the results
my $OUT_nonOvl = $outpref."_nonOverlapping_hits.txt";
my $OUT_choice = $outpref."_highestScore_fromMult.gff";

open(OUT, ">$OUT_nonOvl");
foreach my $key (sort keys %nonOvl) {
	print OUT $key ."\n";
}
close(OUT);

open(OUT, ">$OUT_choice");
open(IN, $MultGFF);
my $printflag = "on";
while(<IN>) {
	my @tab = split(/\t/, $_);
	if($tab[2]=~ m/gene/) {
		my $id = $tab[0]."_".$tab[3]."_".$tab[4];
		my @last = split(/\s;\s/, $tab[8]);
#		print "splitting ".$tab[8]."\n";
		$last[1] =~ m/sequence (\w+)/;
		my $gene = $1;
#		print "printing gene $gene\n";
		if(!defined $nonOvl{$gene} && defined $genes{$gene} && $genes{$gene}{'id'} eq $id) {
			print OUT $_;
			$printflag = "on";
		}
		else {
			$printflag = "off";
		}
	}
	else{
		if($printflag eq "on") {
			print OUT $_;
		}
	}
}
close(IN);
close(OUT);
		
		






















