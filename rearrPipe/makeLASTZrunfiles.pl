#!/usr/bin/perl

# # # # # #
# makeLASTZrunfiles.pl		
# written by Linnéa Smeds                     25 April 2012
# ---------------------------------------------------------
# DESCRIPTION:
# Takes a list of scaffolds and creates individual fasta 
# files for each of them, and make lastz run files for 8
# scaffolds at the time (run in parallel on one node).
# 

use strict;
use warnings;


# Input parameters
my $targetList = $ARGV[0];
my $targetFile = $ARGV[1];
my $query = $ARGV[2];
my $commandpref = $ARGV[3];
my $commandsuff = $ARGV[4];

my $project = "b2011222";
my $time = "10:00:00";

my $outfileCnt = 1;

open(IN, $targetList);
while(<IN>) {

	my $scaff = $_;
	chomp($scaff);

	open(OUT, ">run_lastz_$outfileCnt");

	print OUT "#!/bin/bash -l\n";
	print OUT "#SBATCH -J lastz_$outfileCnt\n";
	print OUT "#SBATCH -o lastz_$outfileCnt.output\n";
	print OUT "#SBATCH -e lastz_$outfileCnt.error\n";
	print OUT "#SBATCH --mail-user linnea.smeds\@ebc.uu.se\n";
	print OUT "#SBATCH --mail-type=ALL\n";
	print OUT "#SBATCH -t $time\n";
	print OUT "#SBATCH -A $project\n";
	print OUT "#SBATCH -p node -n 8\n\n\n";

#	system("perl ~/private/scripts/extractFromFasta.pl $targetFile single $scaff >temp_$scaff.fa");
 
	print OUT $commandpref."temp_".$scaff.".fa ".$query." ".$commandsuff." >".$scaff."_lastz.out &\n\n";

	my $no = 2;
	while($no<=8 && !eof(IN)) {
		my $next = <IN>;
		$scaff = $next;
		chomp($scaff);
		print "looking at $scaff\n";
#		system("perl ~/private/scripts/extractFromFasta.pl $targetFile single $scaff >temp_$scaff.fa");
		print OUT $commandpref."temp_".$scaff.".fa ".$query." ".$commandsuff." >".$scaff."_lastz.out &\n\n";
		$no++;
	}
	print OUT "wait\n";
	close(OUT);
	$outfileCnt++;
}
close(IN);
