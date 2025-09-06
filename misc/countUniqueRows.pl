#!/usr/bin/perl


# # # # # #
# countUniqueRows.pl
# written by Linnéa Smeds 	           April 2013
# ===================================================
# Save the rows in a hash and counts the number of
# unique entries (useful for huge files where it's 
# too memory consuming to use the unix "sort |uniq"
# commands. 
# ===================================================

use strict;
use warnings;

# Input parameters
my $INFILE = $ARGV[0]; 	

my %Hash = ();
open(REF, $INFILE);
while(<REF>) {
	chomp($_);
	$Hash{$_}=1;
}

my $count = scalar(keys %Hash);
print "There are $count unique lines in the file $INFILE\n";

%Hash=();

