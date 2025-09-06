#!/usr/bin/perl

# avgInsertSizePerRegion.pl
# written by Linnéa Smeds                       21 Nov 2017
# Modification of avgInsertSizePerSite.pl that is not as 
# memory demanding. Takes a bed file with regions, extract 
# all read pairs overlapping with that region (with some
# flank around it) and calculates the avg insert size for
# each region.
# =========================================================
# Takes a BAM file and calculates the average insert size
# of all spanning pairs at each position.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max sum];


# Input parameters
my $bam = $ARGV[0];
my $bedfile = $ARGV[1];
my $flank = $ARGV[2];
my $tmpdir=$ARGV[3];
my $output = $ARGV[4];

open(OUT, ">$output");
open(BED, $bedfile);
while(my $line=<BED>) {
  	chomp($line);
  	my @t=split(/\s+/, $line);
	my ($scaff, $start, $stop) = ($t[0], $t[1], $t[2]);
	my $exstart=max($start-$flank, 0);
	my $exstop=$stop+$flank;

	#print "DEBUG: scaff is $scaff and length is $scaffLen\n";

	my $temp = $scaff.".".&rndStr(8).".sam";

	# Use all properly paired that are not marked as duplicates or are secondary:
	system("echo $scaff $exstart $exstop |sed 's/ /\t/g' |samtools view -f 0x0002 -F 0x0500 -L - $bam |awk '(\$7==\"=\" && \$9>0){print}' >$tmpdir/$temp");
	
	my $cnt=0;
	my $sum=0;
	my $min=1000000;
	my $max=0;

	open(IN, "$tmpdir/$temp");
	while(<IN>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[3]<$tab[7]) { #Only check the leftmost read (it contains info on the right read anyway) 

			# Get the maplen from the cigar
			my @cigars = split(/(\d+\w)/, $tab[5]);
			my $maplen = 0;
			for (my $i=0; $i<scalar(@cigars); $i++) {
				if($cigars[$i] =~ m/(\d+)M/ || $cigars[$i] =~ m/(\d+)D/ ) {	#Sums up the length of the read onto the genome (Mapped+Deletions)
					$maplen+=$1;
				}
			}
			# if the right read start before the region, or the left reads ends after the region, we don't have an overlap. All other cases are ok!
			unless($tab[7]<$start || $tab[3]+$maplen>$stop) { 
				$cnt++;	
				$sum+=$tab[8];
				if($tab[8]<$min) {
					$min=$tab[8];
				}
				if($tab[8]>$max) {
					$max=$tab[8];
				}
			}
		}
	}
	close(IN);

	my $avg="UNDEF";
	unless($cnt==0) {
		$avg=$sum/$cnt;
	}
	print OUT $line."\t".$avg."\t".$cnt."\t".$min."\t".$max."\n";

	system("rm $tmpdir/$temp");
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



