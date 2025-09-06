#!/usr/bin/perl

# dealContigsIntoMultFiles.pl
# written by Linnéa Smeds                          Nov 2011
# =========================================================
# 
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $NoFiles = $ARGV[1];
my $prefix = $ARGV[2];

my %hash = ();

open(IN, $fasta);

my ($scaffCnt, $whichFile) = (0,1);
while(<IN>) {
	if($_ =~ m/^>/) {
	
		$hash{$whichFile} .= $_;
	
		my $next = <IN>;
		while ($next !~ m/^>/) {
			$hash{$whichFile} .= $next;
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);

		$scaffCnt++;
		if($whichFile<$NoFiles){
			$whichFile++;
		}
		else {
			$whichFile=1;
		}
	}
}
close(IN);

foreach my $key (keys %hash) {
	my $out = $prefix ."_part".$key.".fsa";
	open(OUT, ">$out");
	print OUT $hash{$key};
	close(OUT);
}



print "Formatted $scaffCnt sequences.\n";

