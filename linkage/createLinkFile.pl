#!/usr/bin/perl


# # # # # #
# createLinkFile.pl
# written by Linnéa Smeds                    Oct 2012
# ===================================================
# Takes a file with anchors, a karyotype file for the
# chromosome in question and a scaffold list with
# directions and lengths (of the type "AllLinked...")
# And creates a link file with the new positions (if
# scaffolds are reversed) and the correct color 
# according to the karyotypefile.
# ===================================================
# Usage: 

use strict;
use warnings;


# Input parameters
my $ANCHORS = $ARGV[0];
my $KARYOTYPE = $ARGV[1];
my $SCAFLIST = $ARGV[2]; 
my $SP = $ARGV[3];			
my $OUTLINKS = $ARGV[4];


#Save karyotype
my %hashmap = ();
open(IN, $KARYOTYPE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	$hashmap{$tab[2]}{'length'}=$tab[5];
	$hashmap{$tab[2]}{'color'}=$tab[6];
}
close(IN);

# Save scaffold orientations
open(IN, $SCAFLIST);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	if(defined $hashmap{$tab[1]}) {
		$hashmap{$tab[1]}{'dir'}=$tab[3];
	}
}
close(IN);


# Go through anchors and save as link file
open(OUT, ">$OUTLINKS");
open(IN, $ANCHORS);
my $printflag = "off";
my $cnt = 1;
while(<IN>) {
	my @tab = split(/\s+/, $_);	
	
#	print "looking at ".$tab[4]."\n";

	if(defined $hashmap{$tab[4]}) {
		my ($newstart, $newend);
		if($hashmap{$tab[4]}{'dir'} eq "-") {
			if($tab[7] eq "-") {
				$newstart = $hashmap{$tab[4]}{'length'}-$tab[6]+1;
				$newend = $hashmap{$tab[4]}{'length'}-$tab[5]+1;
			}
			else {
				$newstart = $hashmap{$tab[4]}{'length'}-$tab[5]+1;
				$newend = $hashmap{$tab[4]}{'length'}-$tab[6]+1;
			}
			my $lowercase = lc($tab[0]);
			print OUT "link_".$cnt." ".$tab[4]." ".$newstart." ".$newend." color=".$hashmap{$tab[4]}{'color'}."\n";
			print OUT "link_".$cnt." ".$SP." ".$tab[1]." ".$tab[2]." color=".$hashmap{$tab[4]}{'color'}."\n";
		}
		else {
			if($tab[7] eq "-") {
				$newstart = $tab[6];
				$newend = $tab[5];
			}
			else {
				$newstart = $tab[5];
				$newend = $tab[6];
			}
			my $lowercase = lc($tab[0]);
			print OUT "link_".$cnt." ".$tab[4]." ".$newstart." ".$newend." color=".$hashmap{$tab[4]}{'color'}."\n";
			print OUT "link_".$cnt." $SP"." ".$tab[1]." ".$tab[2]." color=".$hashmap{$tab[4]}{'color'}."\n";
		}
		$cnt++;
	}
}
close(IN);	
