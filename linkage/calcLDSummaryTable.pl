#!/usr/bin/perl


# # # # # #
# calcLDSummaryTable.pl
# written by Linnéa Smeds                       Feb 2012
# ======================================================
# Goes through all ".ped.out" files in a directory, and
# calculates the mean D' and R^2 for each file along
# with their standard deviation, and also reports the 
# fraction of rows with a p-value lower than some thres. 
# Prints the output to a single file with both collared 
# and pied values. 
# ======================================================
# Usage: perl divideVCFtoSepWindFiles.pl <DIR> <OUTFILE>
#

use strict;
use warnings;
 use List::Util qw(min max); 

# Input parameters
my $dir = $ARGV[0];	 	   
my $outfile = $ARGV[1];

my $pthres = 0.05;

my %windows = ();

# Open given directory and read one file name at the time
opendir(DIR, $dir) or die "can't opendir $dir: $!";
while (defined(my $file = readdir(DIR))) {
	
	#Only look at files including ".ped.out"
	if($file =~ m/\.ped.out/) {
		my @name = split(/[_\-.]/, $file);
		my $scaffold = $name[0];
		my $start = $name[1];
		my $end = $name[2];
		my $sp = $name[4];

#		print "looking at file $file\n";						###Debugging
#		print "looking at $scaffold\n";							###Debugging
#		print "start and stop is $start and $end\n";			###Debugging
#		print "species is $sp\n";								###Debugging
	

		#Open the file and read one line at the time
		open(IN, $dir."/".$file);
		#Skipping the header
		<IN>;													

		my ($noLines,$sumD,$sumR,$smallP)=(0,0,0,0); 
		my (@Ds, @Rs);

		#Loop over all other lines 
		while(my $line = <IN>) {								
			my @tab = split(/\s+/, $line);

			#Skipping lines with "nan"
			unless($line =~ m/nan/) {							
				$sumD+=$tab[1];
				$sumR+=$tab[2];
				push(@Ds, $tab[1]);
				push(@Rs, $tab[2]);		
				if($tab[3]<=$pthres) {
					$smallP++;
				}
				$noLines++;
			}
		}
		close(IN);		

		if($noLines>10) {
			my $meanD = $sumD/$noLines;
			my $meanR = $sumR/$noLines;
			my $percP = $smallP/$noLines;

			#Calculating the SD for D'
			my $sqtotal = 0;
			my ($stdD, $stdR);
			if(scalar(@Ds) == 1) {
				$stdD = 0;
			}
			else {
				foreach(@Ds) {
				        $sqtotal += ($meanD-$_) ** 2;
				}
				$stdD = ($sqtotal / (scalar(@Ds)-1)) ** 0.5;
			}
			#Calculating the SD for R^2
			if(@Rs == 1) {
				$stdR = 0;
			}
			else {
				$sqtotal = 0;
				foreach(@Rs) {
				        $sqtotal += ($meanR-$_) ** 2;
				}
				$stdR = ($sqtotal / (scalar(@Rs)-1)) ** 0.5;
			}
	#		print "Mean D=$meanD, sd=$stdD,  and mean R=$meanR, sd=$stdR\n";	###Debugging

			#Saving all values to hash
			$windows{$scaffold}{$start}{'end'}=$end;
			$windows{$scaffold}{$start}{$sp}{'meanD'}=$meanD;
			$windows{$scaffold}{$start}{$sp}{'stdD'}=$stdD;
			$windows{$scaffold}{$start}{$sp}{'meanR'}=$meanR;
			$windows{$scaffold}{$start}{$sp}{'stdR'}=$stdR;
			$windows{$scaffold}{$start}{$sp}{'smallP'}=$percP;
		}
		else {
			$windows{$scaffold}{$start}{'end'}=$end;
			$windows{$scaffold}{$start}{$sp}{'meanD'}="NA";
			$windows{$scaffold}{$start}{$sp}{'stdD'}="NA";
			$windows{$scaffold}{$start}{$sp}{'meanR'}="NA";
			$windows{$scaffold}{$start}{$sp}{'stdR'}="NA";
			$windows{$scaffold}{$start}{$sp}{'smallP'}="NA";
		}
	}
	
}
close(DIR);

#Open output file for printing 
open(OUT, ">$outfile");
print OUT "#SCAFF\tSTART\tEND\tD'.COL\tsd.D'.COL\tD'.PIE\tsd.D'.PIE\tR2.COL\tsd.R2.COL\tR2.PIE\tsd.R2.PIE\tfrac.P<0.05.COL\tfrac.P<0.05.COL\n";
foreach my $scaf (sort keys %windows) {
	foreach my $start (sort {$a<=>$b} keys %{$windows{$scaf}}) {
		print OUT $scaf."\t".$start."\t".$windows{$scaf}{$start}{'end'}."\t";
		
		if(defined $windows{$scaf}{$start}{'COL'}) {
			#There are values for both col and pied
			if(defined $windows{$scaf}{$start}{'PIE'}) {
				print OUT $windows{$scaf}{$start}{'COL'}{'meanD'}."\t".
					$windows{$scaf}{$start}{'COL'}{'stdD'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'meanD'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'stdD'}."\t".
					$windows{$scaf}{$start}{'COL'}{'meanR'}."\t".
					$windows{$scaf}{$start}{'COL'}{'stdR'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'meanR'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'stdR'}."\t".
					$windows{$scaf}{$start}{'COL'}{'smallP'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'smallP'}."\n";
			}
			#only values for collared
			else  {
				print OUT $windows{$scaf}{$start}{'COL'}{'meanD'}."\t".
					$windows{$scaf}{$start}{'COL'}{'stdD'}."\tNA\tNA\t".
					$windows{$scaf}{$start}{'COL'}{'meanR'}."\t".
					$windows{$scaf}{$start}{'COL'}{'stdR'}."\tNA\tNA\t".
					$windows{$scaf}{$start}{'COL'}{'smallP'}."\tNA\n";
			}
		}
		else {
			#only values for pied
			if(defined $windows{$scaf}{$start}{'PIE'}) {
				print OUT "NA\tNA\t".$windows{$scaf}{$start}{'PIE'}{'meanD'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'stdD'}."\t".
					"NA\tNA\t".$windows{$scaf}{$start}{'PIE'}{'meanR'}."\t".
					$windows{$scaf}{$start}{'PIE'}{'stdR'}."\t".
					"NA\t".$windows{$scaf}{$start}{'PIE'}{'smallP'}."\n";
			}
			#no values at all (should never happen as it is written now)
			else {
				print OUT "NA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\n";
			}
		}
	}
}



