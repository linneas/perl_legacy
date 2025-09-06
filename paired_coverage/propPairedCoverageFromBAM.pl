#!/usr/bin/perl

# pairedCoverageFromBAM.pl
# written by Linnéa Smeds                         July 2011
# =========================================================
# Takes a BAM file and calculates the paired end coverage,
# eq 1X for a certain position means that there is one pair
# spanning this site. [Only use the region BETWEEN the 
# reads for coverage, so see if there is links from left
# side to right side!]
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

	my $temp = $scaff.".".&rndStr(8).".sam";

	# DIFFERENT VERSIONS, UNCOMMENT THE WANTED LINE
	# Use all properly paired:
	# system("samtools view -f 0x0002 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' >$temp");
	# Use only perfectly mapped pairs (UNCOMMENT THIS AND COMMENT THE ABOVE LINE IF WANTED)
	# system("samtools view -f 0x0002 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' |grep \"NM:i:0\" >$temp");
	# Removed Softclipped
	#system("samtools view -f 0x0002 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' |grep \"NM:i:0\" |awk '(\$6!~/S/){print}' >$temp");
	system("samtools view -f 0x0002 -F 0x0500 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' >$temp");

	my %posCov = ();
	for(my $i=1; $i<=$scaffLen; $i++) {
		$posCov{$i} = 0;
	}

	open(IN, $temp);
	while(<IN>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[6] eq "=" && $tab[3]<$tab[7]) {	#Only check the leftmost read (it contains info on the right read anyway) 

			my @cigars = split(/(\d+\w)/, $tab[5]);
			my $maplen = 0;

#			print "DEBUG: cigars is @cigars\tlength of cigar is ".scalar(@cigars)."\n";

			for (my $i=0; $i<scalar(@cigars); $i++) {
				if($cigars[$i] =~ m/(\d+)M/ || $cigars[$i] =~ m/(\d+)D/ ) {	#Sums up the length of the read onto the genome (Mapped+Deletions)
					$maplen+=$1;
#					print "DEBUG: maplen is $maplen\n";
				}
			}
			#Since we look at only the left read in the pair, start is always the  
			#readstart+maplength, and end is always the start of the mate
			my $start = $tab[3]+$maplen;
			my $end = $tab[7]-1;

			for(my $i=$start; $i<=$end; $i++) {
				$posCov{$i}++;
			}
		}
	}
	close(IN);


	#system("rm $temp");


	for(my $i=1; $i<=$scaffLen; $i++) {
		print OUT $scaff."\t".$i."\t".$posCov{$i}."\n";
	} 
}
close(OUT);


sub rndStr {
	my $len=shift;

	my @chars = ("A".."Z", "a".."z");
	my $string="";
	for(my $i=0; $i<$len; $i++) {
  		$string .= $chars[rand @chars];
 	}
	return $string;
}


