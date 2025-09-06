#!/usr/bin/perl

# # # # # #
# blastBioParser.pl
# written by Linnéa Smeds                   6 July 2011
# =====================================================
# 
# =====================================================
# Usage: 
#
# Example: 	
#

use strict;
use warnings;
use Bio::Search::Result::BlastResult;
use Bio::SearchIO;

my $blastFile = $ARGV[0];

 
my $report = Bio::SearchIO->new( -file=>$blastFile, -format => 'blast');
my $result = $report->next_result;
my %hits_by_query;
while (my $hit = $result->next_hit) {
  push @{$hits_by_query{$hit->name}}, $hit;
	my $hitname = $hit->name(); 
	print $hitname;
}
 
foreach my $qid ( keys %hits_by_query) {
  my $result = Bio::Search::Result::BlastResult->new();
  $result->add_hit($_) for ( @{$hits_by_query{$qid}} );
  my $blio = Bio::SearchIO->new( -file => ">$qid\.bls", -format=>'blast' );
  $blio->write_result($result);
}
