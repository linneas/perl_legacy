#!/usr/bin/perl

# # # # # #
# physicalVSgenetic.pl
# written by Linnéa Smeds                       21 Dec 2011
# =========================================================
#
# =========================================================


use strict;
use warnings;

#Input parameters
my $chromScafList = $ARGV[0];		# Five columns (chrom, scaffold, length, direction, comment)
my $physicalList = $ARGV[1];	# Three columns (marker, scaffold, position)
my $geneticList = $ARGV[2];		# Three columns (chrom, marker, position, type)
my $outfile = $ARGV[3];		 


#Save marker physical positions
my %markers = ();
open(IN, $physicalList);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$markers{$tab[1]}{$tab[0]}{'phys'}=$tab[2];
}
close(IN);

open(IN, $geneticList);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	foreach my $key (keys %markers) {
		foreach my $subkey (keys %{$markers{$key}}) {
			if ($tab[1] eq $subkey) {
				$markers{$key}{$subkey}{'gen'}=$tab[2];
				$markers{$key}{$subkey}{'chr'}=$tab[0];
				$markers{$key}{$subkey}{'type'}=$tab[3];
				last;
			}
		}
	}
}
close(IN);


#Go through all chromosomes and make a concatenated list
open(OUT, ">$outfile");
open(IN, $chromScafList);
my $cnt=0;
my $prevChrom = "";
my $cumCnt = 0;
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $markerFlag = "off";
	
	if($prevChrom ne $tab[0]) {
		$cumCnt = 0;
	}

	if($tab[3] eq "+") {
		print "looking at ".$tab[1]." positive direction. Markers and positions are:\n";
		foreach my $key (sort {$markers{$tab[1]}{$a}{'phys'}<=>
							$markers{$tab[1]}{$b}{'phys'}} keys %{$markers{$tab[1]}} ) {

				if(defined $markers{$tab[1]}{$key}{'gen'}) {
					my $tempCum = $cumCnt + $markers{$tab[1]}{$key}{'phys'};
					$tempCum = sprintf("%.2f", $tempCum);
					$markerFlag = "on";

					print OUT $tab[0]."\t".$tab[1]."\t".$key."\t".$markers{$tab[1]}{$key}{'phys'}.
						"\t".$markers{$tab[1]}{$key}{'gen'}."\t".$tempCum."\t".$markers{$tab[1]}{$key}{'type'}."\n";
				}
			print "\t$key ".$markers{$tab[1]}{$key}{'phys'}."\n";
			
		}
	}
	else {
		print "looking at ".$tab[1]." negative direction. Markers and positions are:\n";
		foreach my $key (sort {$markers{$tab[1]}{$b}{'phys'}<=>
							$markers{$tab[1]}{$a}{'phys'}} keys %{$markers{$tab[1]}} ) {

				if(defined $markers{$tab[1]}{$key}{'gen'}) {
					my $tempCum = $cumCnt + ($tab[2]/1000000-$markers{$tab[1]}{$key}{'phys'});
					$tempCum = sprintf("%.2f", $tempCum);
					$markerFlag = "on";

					print OUT $tab[0]."\t".$tab[1]."\t".$key."\t".$markers{$tab[1]}{$key}{'phys'}.
						"\t".$markers{$tab[1]}{$key}{'gen'}."\t".$tempCum."\t".$markers{$tab[1]}{$key}{'type'}."\n";
				}
			print "\t$key ".$markers{$tab[1]}{$key}{'phys'}."\n";
			
		}
	}

	$cumCnt += sprintf("%.2f", ($tab[2]/1000000));
	$prevChrom = $tab[0];
	$cnt++;

}


