#!/usr/bin/perl

# propPairedCoverageFromBAM_giveInsertAndRange.pl
# written by Linnéa Smeds                         July 2011
# =========================================================
# Takes a BAM file and calculates the paired end coverage,
# eq 1X for a certain position means that there is one pair
# spanning this site. 
# This version takes a min and a max insert size, (useful
# for using only paired data from a concatenated bam-file)
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $bam = $ARGV[0];
my $scaf = $ARGV[1];
my $scafStart = $ARGV[2];
my $scafEnd = $ARGV[3];
my $minIns = $ARGV[4];
my $maxIns = $ARGV[5];
my $surround = $ARGV[6];
my $output = $ARGV[7];

my $left = $scafStart-$surround;
my $right = $scafEnd+$surround;
my $temp = "$scaf.temp.sam";

system("samtools view -f 0x0002 $bam $scaf:$left-$right |awk '((\$9>$minIns && \$9<$maxIns) ||(\$9<-$minIns && \$9>-$maxIns)){print}' >$temp");

my %posCov = ();
for(my $i=$scafStart; $i<=$scafEnd; $i++) {
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


#	system("rm $temp");

open(OUT, ">$output");
for(my $i=$scafStart; $i<=$scafEnd; $i++) {
	print OUT $scaf."\t".$i."\t".$posCov{$i}."\n";
}
close(OUT);

