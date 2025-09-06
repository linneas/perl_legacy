#!/usr/bin/perl

# pairedCoverageFromBAM.pl
# written by Linnéa Smeds                         July 2011
# =========================================================
# Takes a BAM file and calculates the paired end coverage,
# eq 1X for a certain position means that there is one pair
# spanning this site. 
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

	#print "scaff is $scaff and length is $scaffLen\n";

	my $temp = "$scaff.temp.sam";

	# Use all properly paired:
	system("samtools view -f 0x0002 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' >$temp");
	# Use only perfectly mapped pairs (UNCOMMENT THIS AND COMMENT THE ABOVE LINE IF WANTED)
	#system("samtools view -f 0x0002 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' |grep \"NM:i:0\" |awk '(\$6!~/S/){print}' >$temp");

	my %posCov = ();
	for(my $i=1; $i<=$scaffLen; $i++) {
		$posCov{$i} = 0;
	}

	open(IN, $temp);
	while(<IN>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[6] eq "=") {

			my @cigars = split(/(\d+\D)/, $tab[5]);
			my $maplen = 0;

#			print "cigars is @cigars\tlength of cigar is ".scalar(@cigars)."\n";

			for (my $i=0; $i<scalar(@cigars); $i++) {
				if($cigars[$i] =~ m/(\d+)M/) {
					$maplen+=$1;
#					print "maplen is $maplen\n";
				}
			}

			my $start = min($maplen+$tab[3]-1,$tab[7]);
			my $end = max($maplen+$tab[3]-1,$tab[7]);
	#		print "start is $start and end is $end\n";

			for(my $i=$start+1; $i<$end; $i++) {
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

