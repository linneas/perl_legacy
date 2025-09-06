#!/usr/bin/perl


# # # # # #
# changePositionsAccAssemblyVersion.pl
# written by Linnéa Smeds		    3 Sept 2012
# =====================================================
# takes a "list of extractions" file and change all
# numbers so they correspond to the newer version of
# the assembly.
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $listOfSplits = $ARGV[0];	 
my $Changes = $ARGV[1];
my $outfile = $ARGV[2];	

# Open output
open(OUT, ">$outfile");

# Save changes
my %changes = ();
open(IN, $Changes);
while(<IN>) {
	my @tab = split(/\s+/, $_);

	my $end = $tab[2];

	if($tab[1]==1) {
		my $next = <IN>;
		my @nexttab = split(/\s+/, $next);
		while ($nexttab[1]==$end+1 && $nexttab[0] eq $tab[0]) {
#			print "finding a consecutive line\n";
#			print "end is $end\n";
			$end = $nexttab[2];
#			print "now end is $end\n";
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
			@nexttab = split(/\s+/, $next);
		}
		seek(IN, -length($next), 1);

		$changes{$tab[0]}=$end;
#		print "Saving ".$tab[0]." with $end\n";
	}
	if(eof(IN)) {
		last;
	}
}
close(IN);

#Open list of splits and change if neccessary
open(SPL, $listOfSplits);
while(<SPL>) {
	my @tab = split(/\s+/, $_);

	if(defined $changes{$tab[0]}) {
		my ($Chr, $No) = split(/:/, $tab[2]);
		unless($No =~ m/-/) {
			my $tempNo = $No-$changes{$tab[0]};
			$tab[2]=~ s/$No/$tempNo/;
		}
		($Chr, $No) = split(/:/, $tab[3]);
		my $tempNo;
		unless($No =~ m/-/) {
			my $tempNo = $No-$changes{$tab[0]};
			$tab[3]=~ s/$No/$tempNo/;
		}
		
		$tab[5] = $tab[5]-$changes{$tab[0]};
		$tab[6] = $tab[6]-$changes{$tab[0]};

		my $line = join("\t",@tab);
		print OUT $line."\n";
		print "changed ".$tab[0]."\n";

	}
	else {
		print OUT $_;
	}
}
close(SPL);
close(IN);



