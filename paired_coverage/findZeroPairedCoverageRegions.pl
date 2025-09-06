#!/usr/bin/perl

# findZeroPairedCoverageRegions.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# Takes the output from pairedCoverageFromBAM.pl and looks
# for zero coverage regions.
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $infile = $ARGV[0];
my $output = $ARGV[1];

open(OUT, ">$output");
open(IN, $infile);
my ($tempcnt, $currstart, $currend) = (0, 0, 0);
my $currcont = "";
my $startflag = "off";
my $zeroflag = "off";
while(<IN>) {
	my ($cont, $pos, $cov) = split(/\s+/,$_);

	if($currcont eq "") {
		$currcont = $cont;
		if ($cov > 0) {
			$startflag = "on";
		}
	}
	else {
		if($startflag eq "on") {
			if($cont eq $currcont){
				if($zeroflag eq "on") {
					if ($cov != 0) {
				#		print "Cont är $cont och currcont är $currcont. Positionen är $pos och cov $cov. Start är $currstart och end är $currend.\n";
				#		#If a "CHECK should be printed alongside with the rest if the region is <50.
				#		if ($currend-$currstart<50) {
				#			print OUT $cont."\t".$currstart."\t".$currend."\tCHECK\n";
				#		}
				#		else {
							print OUT $cont."\t".$currstart."\t".$currend."\n";
				#		}
						$zeroflag = "off";
					}
					else {
						$currend = $pos;
					}
				}
				else {
					if($cov == 0) {
						$zeroflag = "on";
						$currstart = $pos;
						$currend = $pos;
					}
				}
			}
			else {
	#			# If one wants to print the last zero region
	#			if($zeroflag = "on") {
	#				print OUT $cont."\t".$currstart."\t".$currend."\n";
	#				$zeroflag = "off";
	#			}

				if($cov > 0) {
					$startflag = "on";
				}
				else {
					$startflag = "off";
				}
				$zeroflag = "off";
				$currcont = $cont;
			}
		}
		else {
			if ($cov > 0) {
			$startflag = "on";
			}
		}
	}
}
close(IN);
close(OUT);

