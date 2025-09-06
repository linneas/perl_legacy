#!/usr/bin/perl

# avgInsertSizePerSite.pl
# written by Linnéa Smeds                       20 Nov 2017
# NOTE! THIS SCRIPT NEEDS A LOT OF RAM! COULD NOT RUN IT 
# ON CHROMOSOME SCALE EVEN FOR A MICRO CHROMOSOME!
# =========================================================
# Takes a BAM file and calculates the average insert size
# of all spanning pairs at each position.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max sum];


# Input parameters
my $bam = $ARGV[0];
my $lengthFile = $ARGV[1];
my $tmpdir=$ARGV[2];
my $output = $ARGV[3];

open(OUT, ">$output");
open(ALL, $lengthFile);
while(<ALL>) {
	my ($head, $scaffLen) = split(/\t/,$_);
	chomp($scaffLen);
	my ($scaff, $rest) = split(/\s+/,$_);
	$scaff =~ s/>//;

	#print "DEBUG: scaff is $scaff and length is $scaffLen\n";

	my $temp = $scaff.".".&rndStr(8).".sam";

	# Use all properly paired that are not marked as duplicates (or marked as secondary) :
	system("samtools view -f 0x0002 -F 0x0500 $bam $scaff |awk '(\$7==\"=\" && \$9>0){print}' >$tmpdir/$temp");
	
	my %posCov = ();
	for(my $i=1; $i<=$scaffLen; $i++) {
		$posCov{$i} = ();
	}

	open(IN, "$tmpdir/$temp");
	while(<IN>) {
		my @tab = split(/\s+/, $_);
	
		if($tab[6] eq "=" && $tab[3]<$tab[7]) {	#Only check the leftmost read (it contains info on the right read anyway) 

			#Since we look at only the left read in the pair, start is always the  
			#readstart, and end is always the start + the insert size length
			my $start = $tab[3];
			my $end = $tab[3]+$tab[8];

			for(my $i=$start; $i<=$end; $i++) {
				push @{$posCov{$i}}, $tab[8];
			}
		}
	}
	close(IN);


	system("rm $tmpdir/$temp");


	for(my $i=1; $i<=$scaffLen; $i++) {
		my @arr=@{$posCov{$i}};
 		my $avg=sum(@arr)/@arr;
		my $min=min(@arr);
		my $max=max(@arr);
		print OUT $scaff."\t".$i."\t".$avg."\t".$min."\t".$max."\n";
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



