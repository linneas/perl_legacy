#!/usr/bin/perl


# changeOrderOfPeakTable.pl		  	  
# written by Linnéa Smeds                                31 May 2012
# ------------------------------------------------------------------
#
# -----------------------------------------------------------------
# Usage: perl 

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $refColumns = $ARGV[0];
my $Table = $ARGV[1];


#Save the information from the table for each window
my %windows = ();
open(IN, $Table);
my $header = <IN>;
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $scaff = shift @tab;	
	my $start = shift @tab;
	my $end = shift @tab;
	@{$windows{$scaff}{$start}}=@tab;
}
close(IN);


# Go through the correct window list and
# find the right values in the hash
print "CHR\t".$header;
open(TAB, $refColumns);
while(<TAB>) {
	unless(/CHR/) {
		chomp($_);
		my @tab = split(/\s+/, $_);

		if (defined $windows{$tab[1]}{$tab[2]}) {
			my $rest = join("\t",@{$windows{$tab[1]}{$tab[2]}});

			print $_."\t".$rest."\n";
		}
		else {
			print STDERR "there are no values for ".$tab[1]." ".$tab[2]."\n"
		}
	}
}
close(TAB);
