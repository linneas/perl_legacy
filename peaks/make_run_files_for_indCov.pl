#!/usr/bin/perl

# makeRunFilesFromIndCov.pl  	
# written by Linnéa Smeds,                30 March 2012
# =====================================================
# 
# =====================================================
# usage perl


use strict;
use warnings;

# Input parameters
my $DIR = $ARGV[0];
my $outdir = $ARGV[1];



opendir(DIR, $DIR) or die "Cannot open $DIR: $!";
while(my $file = readdir(DIR)) {
	my @names = split(/\./, $file);
	my $scaffold = $names[0];

	my $out = "run_pileup_".$scaffold."\n";
	open(OUT, ">$outdir/$out");

	print OUT "#!/bin/bash -l
#SBATCH -J $scaffold
#SBATCH -o $scaffold.output
#SBATCH -e $scaffold.error
#SBATCH --mail-user linnea.smeds\@ebc.uu.se
#SBATCH --mail-type=ALL
#SBATCH -t 30:00
#SBATCH -A b2010010
#SBATCH -p core

perl ~/private/scripts/peaks/indCov_from_gzpileupFile.pl $DIR/$file $scaffold.pileup

";
	close(OUT);
}

