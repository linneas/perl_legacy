#!/usr/bin/perl


# # # # # #
# blastOutputSummary.pl
# written by Linnéa Smeds                      30 May 2013
# ========================================================
# Takes a blast output file (-m8 format) and summarize the
# results per scaffold (as percent covered)
# ========================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;


my $BLASTOUT = $ARGV[0];	# Blast output (-m8 flag)
my $SCAFLEN = $ARGV[1];		# File with scaffold names and their length
my $TARGETLEN = $ARGV[2];	# File with target names and lengths
my $PREFIX = $ARGV[3];

my $out1 = $PREFIX.".query.summary";
my $out2 = $PREFIX.".target.summary";

my %lengths = ();
open(IN, $SCAFLEN);
while(<IN>) {
	chomp($_);
	my ($scaf, $len) = split(/\s+/, $_);
	$scaf =~ s/>//;
	$lengths{$scaf}=$len;
}
close(IN);

my %tarlengths = ();
open(IN, $TARGETLEN);
while(<IN>) {
	chomp($_);
	my ($seq, $len) = split(/\s+/, $_);
	$seq =~ s/>//;
	$tarlengths{$seq}=$len;
}
close(IN);

my %targets = ();
my %scafCov = ();
my %scafHits = ();

open(IN, $BLASTOUT);
while(<IN>) {
	my @tab = split(/\s+/, $_);

	my $scaf = $tab[0];
	
	if(defined $scafHits{$scaf}{$tab[1]}) {
		$scafHits{$scaf}{$tab[1]}++
	}
	else {
		$scafHits{$scaf}{$tab[1]}=1;
	}
	
	# Go through each base of the hit (query)
	for (my $i=$tab[6]; $i<=$tab[7]; $i++) {
		if(defined $scafCov{$scaf}{$i}) {
			$scafCov{$scaf}{$i}++;
		}
		else {
			$scafCov{$scaf}{$i}=1;
		}
	}

	# same for target
	for (my $i=$tab[6]; $i<=$tab[7]; $i++) {
		if(defined $targets{$tab[1]}{$i}) {
			$targets{$tab[1]}{$i}++;
		}
		else {
			$targets{$tab[1]}{$i}=1;
		}
	}
}
close(IN);

# Print Query summary
open(OUT1, ">$out1");
print OUT1 "#SCAFFOLD	HIT_FRAC	HIT_BP	LENGTH HIT_UNIQ	HIT_MULT	TARGETS\n";
foreach my $hit (keys %scafCov) {
	my $covered = 0;
	my $uniq = 0;
	my $multiple = 0;
	my $trgt = "";
	foreach my $base (keys %{$scafCov{$hit}}) {
		$covered++;
		if($scafCov{$hit}{$base}==1) {
			$uniq++;
		}
		elsif($scafCov{$hit}{$base}>1) {
			$multiple++;
		}
		else {
			print " something is probably very wrong!\n";
		}
	}

	foreach my $t (keys %{$scafHits{$hit}} ) {
			if($trgt eq "") {
				$trgt=$t.":".$scafHits{$hit}{$t};
			}
			else {
				$trgt=$trgt.",".$t.":".$scafHits{$hit}{$t};
			}
	}

	my $frac=$covered/$lengths{$hit};
	my $multfrac = $multiple/$covered;
	my $uniqfrac = $uniq/$covered;
	print OUT1 $hit."\t".$frac."\t".$covered."\t".$lengths{$hit}."\t".$uniqfrac."\t".$multfrac."\t".$trgt."\n";
}
close(OUT1);


#Print target summary
open(OUT2, ">$out2");
print OUT2 "#TARGET	HIT_FRAC	HIT_BP	LENGTH HIT_UNIQ	HIT_MULT\n";

foreach my $seq (keys %targets) {
	my $covered = 0;
	my $uniq = 0;
	my $multiple = 0;
	
	foreach my $base (keys %{$targets{$seq}}) {
		$covered++;
		if($targets{$seq}{$base}==1) {
			$uniq++;
		}
		elsif($targets{$seq}{$base}>1) {
			$multiple++;
		}
		else {
			print " something is probably very wrong!\n";
		}
	}
	my $frac=$covered/$tarlengths{$seq};
	my $multfrac = $multiple/$covered;
	my $uniqfrac = $uniq/$covered;
	print OUT2 $seq."\t".$frac."\t".$covered."\t".$tarlengths{$seq}."\t".$uniqfrac."\t".$multfrac."\n";

}
close(OUT2);
	
