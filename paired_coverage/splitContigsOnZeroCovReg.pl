#!/usr/bin/perl

# splitContigsOnZeroCovReg.pl
# written by Linnéa Smeds                       August 2011
# =========================================================
# 
# =========================================================


use strict;
use warnings;
use List::Util qw[min max];


# Input parameters
my $splitlist = $ARGV[0];
my $assembly = $ARGV[1];
my $basePerLine = $ARGV[2];
my $output = $ARGV[3];


open(IN, $splitlist);
my %newParts = ();
my ($currcont, $partcnt, $partStart) = ("", 1, 1);

while(<IN>) {
	my ($contig, $stop, $start) = split(/\s+/,$_);

	if($currcont eq "") {
		#first part;
		$newParts{$contig}{$partcnt}{'start'}=$partStart;
		$newParts{$contig}{$partcnt}{'stop'}=$stop;
	}
	else {
		if($currcont eq $contig) {
			$newParts{$contig}{$partcnt}{'start'}=$partStart;
			$newParts{$contig}{$partcnt}{'stop'}=$stop;
		}
		else {
			$newParts{$currcont}{$partcnt}{'start'}=$partStart;
			$newParts{$currcont}{$partcnt}{'stop'}='end';
			
			$partcnt=1;
			$partStart=1;
			$newParts{$contig}{$partcnt}{'start'}=$partStart;
			$newParts{$contig}{$partcnt}{'stop'}=$stop;
		}
	}
	$partStart = $start;
	$partcnt++;
	$currcont = $contig;
}
$newParts{$currcont}{$partcnt}{'start'}=$partStart;
$newParts{$currcont}{$partcnt}{'stop'}='end';
close(IN);

open(OUT, ">$output");

open(SEQ, $assembly);
while(<SEQ>) {
	if(/>/) {
		my @line = split(/\s+/, $_);
		$line[0]=~s/>//;

		#Add all sequence lines to one string without newlines
		my $seq;
		my $next = <SEQ>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(SEQ)) {
				last;
			}	
			$next = <SEQ>;
		}
		seek(SEQ, -length($next), 1);

		#The sequence should be splitted
		if(defined($newParts{$line[0]})) {
			foreach my $key (sort {$a<=>$b} keys %{$newParts{$line[0]}}) {

				print OUT ">".$line[0]."-".$key."\n";
	
				my $start = $newParts{$line[0]}{$key}{'start'};
				my $stop = $newParts{$line[0]}{$key}{'stop'};
				if($stop eq 'end') {
					$stop = length($seq);
				}
				my $tempseq = substr($seq, $start-1, $stop-($start-1));
			
				unless(defined $tempseq) {
					print "Det är något fel på ".$line[0]." part $key! Start är $start och stop är $stop\n";
				}

				my @blocks = split(/(.{$basePerLine})/i, $tempseq);
				foreach my $b (@blocks) {
					if($b ne "") {
						print OUT "$b\n";
					}
				}
			}
		}
		else {
			print OUT ">".$line[0]."\n";
			my @blocks = split(/(.{$basePerLine})/i, $seq);
			foreach my $b (@blocks) {
				if($b ne "") {
					print OUT "$b\n";
				}
			}
		}
	}
}
			


















 
