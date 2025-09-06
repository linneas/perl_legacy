#!/usr/bin/perl

# lookForSplitSites.pl
# written by Linnéa Smeds                       3 July 2012
# =========================================================
#
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $sam = $ARGV[0];
my $position = $ARGV[1];
my $lengthFile = $ARGV[2];
my $limit = $ARGV[3];
my $output = $ARGV[4];

# List of bamfiles:
my $BAM1 = "/media/zeus/Genome/alignments/bwa/fAlb13/ins2400_paired.sorted.bam";
my $BAM2 = "/media/zeus/Genome/alignments/bwa/fAlb13/ins4100_paired.sorted.bam";
my $BAM3 = "/media/zeus/Genome/alignments/bwa/fAlb13/ins5100_paired.sorted.bam";
my $BAM4 = "/media/zeus/Genome/alignments/bwa/fAlb13/ins18kb_paired.sorted.bam";
my $BAM5 = "/media/zeus/Genome/alignments/bwa/fAlb13/ins21kb_paired.sorted.bam";

#


my $thres = 1.0;

# Save all links
my %lengths = ();
open(IN, $lengthFile);
while (<IN>) {
	my @tab = split(/\s+/, $_);
	$lengths{$tab[0]}=$tab[1];
}
close(IN);


#Open outfile
open(OUT, ">$output");

# Temporary list file
my $tempName = `date +\%H_\%M_\%S`;
my ($temp, $dummy) = split(/\s+/, $tempName);
$temp = "tempfile_". $temp .".txt";

# Go through the links for each scaffold
open(ALL, $scaffolds);
while(<ALL>) {
	my @tab = split(/\s+/,$_);
	my $scaff = $tab[0];
	my $len = $tab[1];

	
	print "DEBUG: Looking at $scaff\n";
 

	my $startSign = "";
	my $endSign = "";
	my $StartDir = "";
	my $EndDir = "";
	my $thisNo = "";

	# Check start of scaffold
	system("awk '(\$3==\"$scaff\" && \$4<$limit && \$2!~/r/){print}' $sam |cut -f7 |sort |uniq -c |sort -nr >$temp");
	
	open(TMP, $temp);
	my $cnt=0;
	my $totLinks=0;
	my @NoARR=(0,0,0);
	my @NameARR=("","","");
	while(my $line=<TMP>) {
		my ($s1, $No, $Name) = split(/\s+/, $line);
		$NoARR[$cnt]=$No;
		$NameARR[$cnt]=$Name;
#		print "adding $Name and $No to the array\n";
		$cnt++;
		$totLinks+=$No;
	}
	close(TMP);	

	print "first is ".$NameARR[0].", second is ".$NameARR[1]." and third is ".$NameARR[2]."\n";

	if($NoARR[1]+$NoARR[2]==0 || $NoARR[0]/($NoARR[1]+$NoARR[2])>$thres) {
		print "Start of $scaff is significantly connected to ".$NameARR[0]." with ".$NoARR[0]." links\n";
		$startSign="*";
	}

	# Check if the links are in the start/end of the new scaffold
	my $top = $NameARR[0];
	my $toStart = `awk '(\$3==\"$scaff\" && \$4<$limit && \$2!~/r/ && \$7==\"$top\" && \$8<$limit && \$2!~/R/){print}' $sam |wc -l`;
	chomp($toStart);
	my $tempLim = $lengths{$top}-$limit;
	my $toEnd = `awk '(\$3==\"$scaff\" && \$4<$limit &&  \$2!~/r/ && \$7==\"$top\" && \$8>$tempLim && \$2~/R/){print}' $sam |wc -l`;
	chomp($toEnd);
	print "Start of $scaff have $toStart links to start of ".$top." and $toEnd links to end\n";

	if($toStart>$toEnd) {
		$StartDir="+";
		$thisNo = $toStart;
	}
	else {
		$StartDir= "-";
		$thisNo = $toEnd;
	}
		
	print OUT $scaff."\t".$NameARR[0].$startSign."(".$StartDir.")($thisNo/$totLinks)\t";

	 # Check end of scaffold
	my $tempEnd = $len-$limit;
	system("awk '(\$3==\"$scaff\" && \$4>$tempEnd && \$2~/r/){print}' $sam |cut -f7 |sort |uniq -c |sort -nr >$temp");
	
	open(TMP, $temp);

	@NoARR=(0,0,0);
	@NameARR=("","","");
	$cnt=0;
	$totLinks=0;
	while(my $line=<TMP>) {
		my ($s1, $No, $Name) = split(/\s+/, $line);
		$NoARR[$cnt]=$No;
		$NameARR[$cnt]=$Name;
#		print "adding $Name and $No to the array\n";
		$cnt++;
		$totLinks+=$No;
	}
	close(TMP);	

	print "first is ".$NameARR[0].", second is ".$NameARR[1]." and third is ".$NameARR[2]."\n";

	if($NoARR[1]+$NoARR[2]==0 || $NoARR[0]/($NoARR[1]+$NoARR[2])>$thres) {
		print "End of $scaff is significantly connected to ".$NameARR[0]." with ".$NoARR[0]." links\n";
		$endSign="*";
	}

	# Check if the links are in the start/end of the new scaffold
	$top = $NameARR[0];
	my $tempStartLim = $lengths{$scaff}-$limit;
	$toStart = `awk '(\$3==\"$scaff\" && \$4>$tempStartLim && \$2~/r/ && \$7==\"$top\" && \$8<$limit && \$2!~/R/){print}' $sam |wc -l`;
	chomp($toStart);
	$tempLim = $lengths{$top}-$limit;
	$toEnd = `awk '(\$3==\"$scaff\" && \$4>$tempStartLim && \$2~/r/ && \$7==\"$top\" && \$8>$tempLim && \$2~/R/){print}' $sam |wc -l`;
	chomp($toEnd);

	if($toStart>$toEnd) {
		$EndDir="+";
		$thisNo = $toStart;
	}
	else {
		$EndDir= "-";
		$thisNo = $toEnd;
	}

	print "End of $scaff have $toStart links to start of ".$top." and $toEnd links to end\n";

	print OUT $NameARR[0].$endSign."(".$EndDir.")($thisNo/$totLinks)\n";


}
close(ALL);
