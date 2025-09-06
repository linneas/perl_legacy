#!/usr/bin/perl


# # # # # #
# getTaxon.pl
# written by Linnéa Smeds		  15 April 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;
use Bio::DB::Taxonomy::entrez; 


my $inputList = $ARGV[0];
my $outputList = $ARGV[1];

open(OUT, ">$outputList");

my $db = Bio::DB::Taxonomy->new(-source => 'entrez');
my $species = "Acinetobacter";
my $taxonid = $db->get_taxonid($species);
my $taxon = $db->get_taxon(-taxonid => $taxonid);


print "taxonid is $taxonid\n";
print "the new species has a taxon ".$taxon."\n";
print $species."\t".$taxon->division."\n";

open(IN, $inputList);
while(<IN>) {
	$_ =~ m/\s+(\d+)\s+(.+)/;
	sleep 1;
	my $no = $1;
	my $species = $2;

	print "no is $no, and species $species\n";
	
	my $taxonid = $db->get_taxonid($species);
	print "taxonid is $taxonid\n";

	if($taxonid) {
		my $taxon = $db->get_taxon(-taxonid => $taxonid);
		sleep 1;
		my $division = $taxon->division();
		print OUT $no."\t".$species."\t".$division."\n";
	}
	else {
		print "species $species has no taxonID\n";
		$species =~ m/(\w+)\s+(\w+)/;
		my $newspecies = $1;
		print "my new species is $newspecies\n";
		my $newtaxonid = $db->get_taxonid($newspecies);
		if($newtaxonid) {
			print "the new species has a number: $newtaxonid\n";
			my $newtaxon = $db->get_taxon(-taxonid => $newtaxonid);
			sleep 1;
			my $division = $newtaxon->division();

			print "the new species has a taxon ".$newtaxon."\n";
			print "the new species has a rank ".$newtaxon->rank."\n";
			print "the new species has a division $division\n";
			print OUT $no."\t".$species."\t".$division."\n";
		}
		else {
			print "new species has no new id\n";
			print OUT $no."\t".$species."\tUNKNOWN\n";
		}
	}
}
