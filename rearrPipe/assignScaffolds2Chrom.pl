#!/usr/bin/perl


# # # # # #
# assignScaffolds2Chrom.pl
# written by Linnéa Smeds		  14 April 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;

# Input parameters
my $MultList = $ARGV[0];	#A list with names of scaffolds that anchors to mult chromosomes
my $AllCatList = $ARGV[1];	#Concatenated *cat.list files, with three columns, chrom, scaff and strand.
my $lengthFile = $ARGV[2];	#a two columns file with scaffold name (without >) and length
my $fileEnding = $ARGV[3]; 	#extension for the anchorfiles, ex "step5.anchors"
my $chromList = $ARGV[4];	# a list with all chromosomes
my $multOut = $ARGV[5];


my $splitThres = 0.95;

# Save all lengths in a hash
my %lengths = ();
open(IN, $lengthFile);
while(<IN>) {
	my ($scaff, $len) = split(/\s+/, $_);
	$lengths{$scaff}=$len;
} 
close(IN);


#Save all chromosomes in an array
my @chromosomes;
open(IN, $chromList);
while(<IN>) {
	chomp($_);
	push(@chromosomes, $_);
}
close(IN);

#print "the chromosomes are @chromosomes\n";

# Make a list of which chromosomes the scaffolds should be assigned to. 
my %assignedList = ();


open(OUT, ">$multOut");
open(OUT2, ">splittingInfo");
#Go through the text file
open(IN, $MultList);
#print "open file $MultList\n";
while(<IN>) {
#	print "file is open\n";
	my $scaff = $_;
	chomp($scaff);
	print "looking at $scaff\n";
	my %chrms=();

	open(ALL, $AllCatList);
	while(my $line = <ALL>) {
	 	if(defined $line) { 
			my ($chr, $sc, $strand) = split(/\s+/, $line);
			if($scaff eq $sc) {
				$chrms{$chr}=1;
#				print "saving $chr in hash\n";
			}
		}
	}
	close(ALL);

	my $maxFrac = 0;
	my $assigned = "";
	my $sumFrac = 0;
	my $tempPrint = "";

	print $scaff." anchors to:\n";
	foreach my $key (keys %chrms) {
#		print "looking at $key\n";

		my $anchorLen = 0;

		open(ANC, $key."_".$fileEnding);
#		print "inspecting file ".$key."_".$fileEnding."\n";
		while(my $line = <ANC>) {
			my @tab = split(/\s+/, $line);

			if($tab[4] eq $scaff) {
				$anchorLen+=abs($tab[6]-$tab[5]);
			}
		}
		my $frac = $anchorLen/$lengths{$scaff};
#		print "length of anchor: $anchorLen\tlength of scaffold: ".$lengths{$scaff}."\n";
#		print "fraction is $frac\n";
		
		if($key ne "chrUn") {
			$sumFrac+= $frac;
			if ($frac > $maxFrac) {
				$maxFrac = $frac;
				$assigned = $key;
			}
		} 

		print "\t$key\t$anchorLen\t$frac\n";
		$tempPrint .= "\t$key\t$anchorLen\t$frac\n";
	}
	print "\t\tAssigned to $assigned\n";
	$assignedList{$scaff}=$assigned;
	
	if($sumFrac == 0) {
		print "something is wrong for scaffold $scaff!\n";
	}
	elsif($maxFrac/$sumFrac<$splitThres) {
		print "\t\tOUPS! Seems like we have a split\n";
		print OUT $scaff."\n";
		print OUT2 $scaff."\n";
		print OUT2 $tempPrint;		
	}
}
close(IN);
close(OUT);
close(OUT);

foreach(@chromosomes) {
	my $chr = $_;
	my $file = $_ ."_cat.list";
	my $secfile = $_ ."_".$fileEnding;
	print "file is $file\n";
	my $outfile = $file.".cleaned";
	my $secoutfile = $secfile.".cleaned";

	open(IN, $file);
	open(OUT, ">$outfile");
	while(my $line = <IN>) {
		chomp($line);
		unless($line eq "") {
			my ($inscaff, $sign) = split(/\s+/, $line);
			if(defined $assignedList{$inscaff}) {
				if ($assignedList{$inscaff} ne $chr) {
					print "$inscaff is removed from $file\n";
				}
				else {
					print OUT $line."\n";
				}
			}
			else {
				print OUT $line."\n";
			}
		}
	}
	close(IN);
	close(OUT);

	open(IN, $secfile);
	open(OUT, ">$secoutfile");
	while(my $line = <IN>) {
		chomp($line);
		unless($line eq "") { 
			my @tab = split(/\s+/, $line);
			if(defined $assignedList{$tab[4]}) {
				if ($assignedList{$tab[4]} ne $chr) {
					print $tab[4]." is removed from $secfile\n";
				}
				else {
					print OUT $line."\n";
				}
			}
			else {
				print OUT $line."\n";
			}
		}
	}
	close(IN);
	close(OUT);
		

}


