#!/usr/bin/perl


# # # # # #
# makeLinksFromNucmerCoords.pl
# written by Linnéa Smeds                14 June 2017
# ===================================================
# 
# ===================================================
# Usage: 

use strict;
use warnings;


# Input parameters
my $ANCHORS = $ARGV[0];		# only the six important columns from coords, s1,e1,s2,e2,scaf1,scaf2 - WITHOUT HEADER
my $KARYOTYPE = $ARGV[1];
my $COLORS = $ARGV[2];		#"karyo" (from karyotype) or "ori" (based on orientation)
my $OUTLINKS = $ARGV[3];

# Other parameters
my ($forcol,$revcol);
$forcol = "blue";
$revcol = "red";

unless($COLORS eq "karyo" || $COLORS eq "ori") {
	die "Colors must be specified as either karyo or ori (orientation)\n";
}

#Save karyotype
my %hash = ();
open(IN, $KARYOTYPE);
while(<IN>) {
	chomp($_);
	my @tab = split(/\s+/, $_);
	my @d = split(/[()]/, $tab[3]);
	$hash{$tab[2]}{'length'}=$tab[5];
	$hash{$tab[2]}{'dir'}=$d[1];
	$hash{$tab[2]}{'col'}=$tab[6];
#	print "DEBUG: Saving ".$tab[2]." with length ".$tab[5]." and orientation ".$d[1]."\n";
}
close(IN);


# Go through anchor file and convert to link format
open(OUT, ">$OUTLINKS");
open(IN, $ANCHORS);
my $printflag = "off";
my $cnt = 1;
while(<IN>) {
	my @tab = split(/\s+/, $_);
	
	# Checking that both scaffolds are present in the karyotype
	if(defined $hash{$tab[0]} && defined $hash{$tab[4]}) {
#		print "DEBUG: Both ".$tab[0]." and ".$tab[5]." are defined in the hash\n";
		my ($s1, $e1, $s2, $e2, $col);

		# Setting colors (flip if the two scaffolds have different orientation!)
		if($tab[7] eq "+"){
			$col=$forcol;
		}
		else {
			$col=$revcol;
		}


		# If both scaffolds are plusoriented, OR both scaffolds are minus oriented,
		# the alignmentorientation is kept!
		if($hash{$tab[0]}{'dir'} eq $hash{$tab[4]}{'dir'}) {		

			# if +, the coordinates are kept as well
			if($hash{$tab[0]}{'dir'} eq "+") {
				$s1=$tab[1];
				$e1=$tab[2];
				if($tab[7] eq "+") {
					$s2=$tab[5];
					$e2=$tab[6];
				}
				else {
					$s2=$tab[6];
					$e2=$tab[5];
				}
			}
		
			# if -, all coordinates should be inverted
			else {
				$s1=$hash{$tab[0]}{'length'}-$tab[1]+1;
				$e1=$hash{$tab[0]}{'length'}-$tab[2]+1;
				if($tab[7] eq "+") {
					$s2=$hash{$tab[4]}{'length'}-$tab[5]+1;
					$e2=$hash{$tab[4]}{'length'}-$tab[6]+1;
				}
				else {
					$s2=$hash{$tab[4]}{'length'}-$tab[6]+1;
					$e2=$hash{$tab[4]}{'length'}-$tab[5]+1;
				}
					
			}
		}
		else {	#They are different!
			if($col eq $forcol) {	
				$col=$revcol;
			}
			else {
				$col=$forcol;
			}

			if($hash{$tab[0]}{'dir'} eq "+") {	#if the first is +, the second is -
				$s1=$tab[1];
				$e1=$tab[2];
				if($tab[7] eq "+") {
					$s2=$hash{$tab[4]}{'length'}-$tab[5]+1;
					$e2=$hash{$tab[4]}{'length'}-$tab[6]+1;
				}
				else {
					$s2=$hash{$tab[4]}{'length'}-$tab[6]+1;
					$e2=$hash{$tab[4]}{'length'}-$tab[5]+1;
				}

			
			}
			else {
				$s1=$hash{$tab[0]}{'length'}-$tab[1]+1;
				$e1=$hash{$tab[0]}{'length'}-$tab[2]+1;
				if($tab[7] eq "+") {
					$s2=$tab[5];
					$e2=$tab[6];
				}
				else {
					$s2=$tab[6];
					$e2=$tab[5];
				}

			}
		}

		# Print
		if($COLORS eq "karyo") {
			$col=$hash{$tab[4]}{'col'};
		}
		print OUT "link_".$cnt." ".$tab[0]." ".$s1." ".$e1." color=".$col."\n";
		print OUT "link_".$cnt." ".$tab[4]." ".$s2." ".$e2." color=".$col."\n";
		$cnt++;

	}
}
close(IN);
