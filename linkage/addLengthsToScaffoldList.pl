#!/usr/bin/perl


# # # # # #
# addLengthsToScaffoldList.pl
# written by Linnéa Smeds                  14 Sept 2011
# =====================================================
# Takes a list with scaffolds (and possibly two other 
# columns) and the scaffold length file as input, and
# prints a new list with the desired scaffolds, their 
# length (and the extra columns if they exist)
# =====================================================


use strict;
use warnings;

#Input parameters
my $list = $ARGV[0];		#Two columns; number and latin name
my $lengthFile = $ARGV[1];	#A list with all scaffolds and their lengths


open(IN, $list);
my %scaffs = ();
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	$scaffs{$tabs[0]}="void";
}
close(IN);

open(IN, $lengthFile);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	if(defined $scaffs{$tabs[0]}) {
		chomp($tabs[1]);
		$scaffs{$tabs[0]}=$tabs[1];
	}
}
close(IN);

open(IN, $list);
while(<IN>) {
	my @tabs = split(/\s+/, $_);
	my $scaff = shift @tabs;
	$_ =~ s/$scaff\t//;
	my $rest = join("\t", @tabs);
	print $scaff."\t".$scaffs{$scaff}."\t".$_;
}
close(IN);

