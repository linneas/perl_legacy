#!/usr/bin/perl

# changeFastaHeaders.pl
# written by Linnéa Smeds                    16 Jan 2012
# ======================================================
# Uses a map file to change the headers in a fasta file.
# The map file has two columns: OLD_HEAD and NEW_HEAD. 
# ======================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $mapFile = $ARGV[1];
my $output = $ARGV[2];

my $bpPerRow = 80;

my %map=();
open(IN, $mapFile);
while(<IN>){
	my ($old, $new) = split(/\s+/, $_);
	$map{$old}=$new;
}
close(IN);


open(IN, $fasta);
open(OUT, ">$output");
my $cnt=0;
while(<IN>) {
	if($_ =~ m/^>/) {
		chomp($_);
		$_ =~ s/>//;
		
		my $head = $map{$_};
		print OUT ">".$head."\n";
		$cnt++;
	}
	else {
		my $line = uc($_);
		print OUT $_;
	}
}
close(IN);
close(OUT);

print "Formatted $cnt sequences.\n";

