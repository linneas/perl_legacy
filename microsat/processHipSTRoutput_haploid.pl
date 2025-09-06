#!/usr/bin/perl

# processHipSTRoutput.pl  	
# written by Linnéa Smeds,                   8 May 2017
# Modified the 4th of July 2018 to handle haploid calls.
# =====================================================
# Takes the vcf like output of HipSTR and convert the 
# genotypes (e.g. ACACACACACACACACACA) to the length
# of the (perfect) repeat instead. 
#
# The id in column 3 must be PATTERN_*something* to be
# used for matching. The GT does not only contain
# perfect repeats, but sometimes junk around it, or 
# incomplete repeats. 
# If the GT is ACACGCACACACACACACACACACACACACCTTC
# and the pattern is CA, we want to replace it with
# 24 (length of the longest (CA) and not 4 (length of
# the first (CA), which is part of the junk before 
# the repeat, not part of repeat itself).
# =====================================================
# usage: perl processHipSTRoutput.pl  	

use strict;
use warnings;
my $time=time;
use List::Util qw(min max);

# Input parameters
my $VCF = $ARGV[0];	# VCF like file, 9 + 1xIND columns (will only manipulate 
					# columns 4 & 5)
my $OUT = $ARGV[1];


# Open outfile handle
open(OUT, ">$OUT");


print STDERR "Going through VCF like HipSTR output...\n";
my $cnt=0;
open(IN, $VCF);
while(<IN>) {
	if(/#/) {
		print OUT;
	}
	else {
		my @tab=split(/\s+/, $_);

		my %hash=();

		# Find pattern
		$tab[2]=~m/(\D+)_\d+/;
		my $pattern=$1;
#		print $tab[2]."\t".$pattern."\n";

		# Find lengths of reference
		my @hits = $tab[3] =~ m/(($pattern)+)/g;
		my $reflen=0;
		for my $h (@hits) {
			if(length($h)>$reflen) {
#				print "\tDEBUG: looking at hit $h\n";
				$reflen=length($h);
			}
		}
		$hash{0}=$reflen;

		#Find lengths of alternative(s)
		my @alts = split(/,/, $tab[4]);
		my @altlen=();
		my $c=1;
		for my $a (@alts) {
			my @hits = $a =~ m/(($pattern)+)/g;
			my $alt=0;
			for my $h (@hits) {
				if(length($h)>$alt) {
					$alt=length($h);
				}
			}
			push @altlen, $alt;
			$hash{$c}=$alt;
			$c++;
		}

		# Replace individual columns with only the GT (given as len)
		for(my $i=9; $i<scalar(@tab); $i++) {
			if($tab[$i] eq ".") {
			}	
			else {
				my @t = split(/:/, $tab[$i]);
				my $newGT=$hash{$t[0]};
				$tab[$i]=$newGT;
			}
		}

#		print "DEBUG: ".$tab[0]."\t".$tab[1]."\t".$tab[2]."\t".$tab[3]."\t".$reflen."\t".$tab[4]."\t".join(",", @altlen)."\n";
#		print "DEBUG: ".$tab[2]."\t".$reflen."\t".join(",", @altlen)."\n";
		
		$tab[3]=$reflen;
		$tab[4]=join(",", @altlen);

		print OUT join("\t", @tab)."\n";

	}

}


print STDERR "...Done!\n";

$time=time-$time;
print STDERR "Total time elapsed: $time sec\n";
