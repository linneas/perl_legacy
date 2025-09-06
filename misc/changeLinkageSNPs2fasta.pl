#!/usr/bin/perl


# # # # # #
# changeLinkageSNPs2fasta.pl
# written by Linnéa Smeds		   4 April 2011
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
my $linkTxt = $ARGV[0];


#Go through the text file
open(IN, $linkTxt);
while(<IN>) {
	if($_ =~ m/\w+/) {
		my ($name, $no, $transcr, $seq) = split(/\s+/, $_);
		if ($seq eq "") {
			my $next = <IN>;
			chomp($next);
			while ($next ne "") {
				$seq.= $next;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
				chomp($next);
			}
			seek(IN, -length($next), 1);
		}
		$seq =~ s/\[(\w)\/\w\]/$1/;

		if($seq =~ m/\[\w+_\w+_\w+_(\d+)_\w+\]/) {
			my $temp = "";
			for(my $i=0; $i<$1; $i++) {
				$temp.="N";
			}
			$seq =~ s/\[\w+_\w+_\w+_(\d+)_\w+\]/$temp/;
		}

		my $length = length($seq);
					
		print ">".$name."_".$no."_len=".$length."\n";
		print $seq."\n";
	}
}
