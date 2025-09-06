#!/usr/bin/perl

# propPairedCoverageFromBAM_useFullInsert.pl
# written by Linnéa Smeds                       20 Nov 2017
# Changed from propPairedCoverageFromBAM to take the full 
# range of a pair i.e. use region from end to end (the 
# former only used the region BETWEEN in the reads).
# Only consider NON duplicates
# =========================================================
# Takes a BAM file and calculates the properly paired end 
# coverage eq 1X for a certain position means that there is
# one pair spanning this site. 
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $bam = $ARGV[0];
my $lengthFile = $ARGV[1];
my $output = $ARGV[2];

open(OUT, ">$output");
open(ALL, $lengthFile);
while(<ALL>) {
	my ($head, $scaffLen) = split(/\t/,$_);
	chomp($scaffLen);
	my ($scaff, $rest) = split(/\s+/,$_);
	$scaff =~ s/>//;

	#print "DEBUG: scaff is $scaff and length is $scaffLen\n";

	my $temp = "$scaff.temp.sam";

	# Use all properly paired that are not marked as duplicates (or marked as secondary!) :
	system("samtools view -f 0x0002 -F 0x0500 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' >$temp");
	
	my %posCov = ();
	for(my $i=1; $i<=$scaffLen; $i++) {
		$posCov{$i} = 0;
	}

	open(IN, $temp);
	while(<IN>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[6] eq "=" && $tab[3]<$tab[7]) {	#Only check the leftmost read (it contains info on the right read anyway) 

			#Since we look at only the left read in the pair, start is always the  
			#readstart, and end is always the start + the insert size length
			my $start = $tab[3];
			my $end = $tab[3]+$tab[8];

			for(my $i=$start; $i<=$end; $i++) {
				$posCov{$i}++;
			}
		}
	}
	close(IN);


	system("rm $temp");


	for(my $i=1; $i<=$scaffLen; $i++) {
		print OUT $scaff."\t".$i."\t".$posCov{$i}."\n";
	} 
}
close(OUT);

