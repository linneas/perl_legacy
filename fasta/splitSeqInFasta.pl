#!/usr/bin/perl

# splitSeqInFasta.pl
# written by Linnéa Smeds                         June 2010
# =========================================================
# Takes a fasta file and splits the sequences at every Xth
# bases with a given overlap. (Set overlap to 0 to get a
# copy of the input but with a max sequence legth of X. 
# =========================================================


use strict;
use warnings;

# Input parameters
my $fasta = $ARGV[0];
my $maxLen = $ARGV[1];
my $overlap = $ARGV[2];
my $output = $ARGV[3];

print "splittning sequences on length $maxLen\n";
print "with overlap $overlap\n";

my ($seq,$head) = ("","");
open(IN, $fasta);
open(OUT, ">$output");
my ($scaffCnt,$newCnt) = (0,0);
while(<IN>) {
	if($_ =~ m/^>/) {
		chomp($_);
		$scaffCnt++;
		my $head = $_;
		my $seq = ();
		my $next = <IN>;
		while ($next !~ m/^>/) {
			chomp($next),
			$seq.= $next;
			if(eof(IN)) {
				last;
			}	
			$next = <IN>;
		}
		seek(IN, -length($next), 1);

		my $cnt = 1;
		
		while(length($seq)>$maxLen) {
			my $temp = substr($seq, 0, $maxLen);
			$seq = substr($seq, $maxLen-$overlap, length($seq)-$maxLen+$overlap);
			$newCnt++;
			print OUT $head."_part".$cnt."\n";
			my @blocks = split(/(.{100})/i, $temp);
			foreach my $b (@blocks) {
				if($b ne "") {
					print OUT "$b\n";
				}
			}
			$cnt++;
		}
		 $newCnt++;
		print OUT $head."_part".$cnt."\n";
		my @blocks = split(/(.{100})/i, $seq);
		foreach my $b (@blocks) {
			if($b ne "") {
				print OUT "$b\n";
			}
		}
	}
}


print "$scaffCnt sequences in original file\n";
print "$newCnt sequences after splitting\n";

close(IN);
close(OUT);
