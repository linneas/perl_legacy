#!/usr/bin/perl

# # # # # #
# printExtractLinks_commands.pl
# written by Linnéa Smeds, Oct 2012
# =========================================================
# 
# =========================================================


use strict;
use warnings;

# Input parameters
my $MAX = $ARGV[0];
my $RANGE = $ARGV[1];	
my $OUTPREF = $ARGV[2];

my $fileCnt = 1;

for(my $i=1; $i<=$MAX; $i=$i+($RANGE*8)) {

	print "Now i is $i!\n";
	
my $out = $OUTPREF."_part".$fileCnt.".sh";
		open(OUT, ">$out");
		print OUT "#!/bin/bash -l
#SBATCH -J extract_links$fileCnt
#SBATCH -o extract_links$fileCnt.output
#SBATCH -e extract_links$fileCnt.error
#SBATCH --mail-user linnea.smeds\@ebc.uu.se
#SBATCH --mail-type=ALL
#SBATCH -t 3:00:00
#SBATCH -A b2010010
#SBATCH -p node

# New bwa version
module load bioinfo-tools
module load bwa/0.6.2
module load samtools

";

	for(my $j=$i; $j<$i+($RANGE*8); $j+=$RANGE) {
	
		my $end = $j+$RANGE-1;	

		print "Now j is $j and end is $end!\n";	

		print OUT "head -n$end ../../FicAlb1.4.lengths |tail -n$RANGE | perl ~/private/scripts/alignments/checkAllEndsForLinks_prePrepSAMTEST_countLinks.pl ../edge_2-21kb.sam -  ../../FicAlb1.4.lengths 20000 Scaffold_links_$j-$end.txt >out$j-$end &
sleep 1
";

	}

	print OUT "\nwait\n";
	close(OUT);
	$fileCnt++;
}

