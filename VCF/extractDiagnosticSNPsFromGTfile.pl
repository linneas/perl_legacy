#!/usr/bin/perl

# extractDiagnosticSNPsFromGTfile.pl
# written by Linnéa Smeds                       20 Aug 2018
# =========================================================
# Takes a list of individual names and a genotype file (a 
# condensed version of VCF that only contains scaffold, pos
# and one column per ind with it's allele (either the GT
# column (like 0/0 or 0) or translated to bases (like A/A 
# or A).
# Returns a list of SNPs where ALL the individuals on the
# list has one GT, and ALL the other inds has another. 
#
# NOTE: This version of the script assumes that one or more
# outgroups are included which will guarantee that when the
# selected (in)group has a unique SNP, it must be the derived
# allele (if one selects the outgroup, or doesn't include 
# an outgroup at all, the script will still work but the
# header "ANC" and "DER" has no meaning. (However changing
# it to "NON_SELECTED" and "SELECTED" makes it correct). 
# =========================================================


use strict;
use warnings;

# Input parameters
my $INDLIST = $ARGV[0];
my $GTFILE = $ARGV[1];
my $OUT = $ARGV[2];

# Save all wanted INDs in a hash
my %inds = ();
open(IN, $INDLIST);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	$inds{$tab[0]}=1;
}
close(IN);

# Then go through the SNPs and check all wanted and unwanted. As soon as a mis-
# match within any of the groups are found, skip and go to next SNP. 

open(GT, $GTFILE);
open(OUT, ">$OUT");
print OUT "#SCAFFOLD\tPOS\tANC\tDER\n";

# Go through the SNPs - but first save the individual names from the header
my $firstrow=<GT>;
my @header=split(/\s+/, $firstrow);


while(<GT>) {

	my $printflag="on";
	my ($anc, $der) = ("","");
	my @tab = split(/\s+/, $_);
	print STDERR "DEBUG: Looking at ".$tab[0].":".$tab[1]."\n";

	for(my $i=2; $i<scalar(@tab); $i++) {

		if(defined $inds{$header[$i]}) {	# We have a wanted! 
			print STDERR "\tFound a wanted! (".$header[$i].")\n";
			if($der eq "") {		# ..and if its the first one
				if($tab[$i] ne $anc) {  # (and not the same as unwanted)
					$der=$tab[$i];		# - set it
					print STDERR "\t\t..and set it to $der\n";
				}
				else {
					$printflag="off";
					print STDERR "------->ABORT - new wanted ind (".$header[$i].") has same GT ".$tab[$i]." as unwanted $anc\n";
					last;
				}

			}
			else {			#..not the first one
				unless($der eq $tab[$i]) {	#not the same!
					$printflag="off";
					print STDERR "------->ABORT - new ind (".$header[$i].") has GT ".$tab[$i]." different to $der\n";
					last;
				}
			}
		}
		else {					# We have an unwanted!
			print STDERR "\tFound an unwanted! (".$header[$i].")\n";
			if($anc eq "") {		#..first one 
				if($tab[$i] ne $der) {	# (and it's not the same as the wanted)
					$anc=$tab[$i];
					print STDERR "\t\t..and set it to $anc\n";
				}
				else {			#gt is identical to already defined wanted
					print STDERR "--------->ABORT  - New unwanted ind (".$header[$i].") has same gt (".$tab[$i].") as wanted ($der)\n";
					$printflag="off";
					last;
				}
			}
			else {				#.. not the first one, 
				unless($anc eq $tab[$i]) {
					print STDERR "--------->ABORT  - New unwanted ind (".$header[$i].") has GT (".$tab[$i].") different to $anc\n";
					$printflag="off";
					last;
				}
			}
		}
	}

	# If printflag is still on, the SNP is diagnostic!
	if($printflag eq "on") {
		print OUT $tab[0]."\t".$tab[1]."\t".$anc."\t".$der."\n";
	}
}
close(IN);
close(OUT);



