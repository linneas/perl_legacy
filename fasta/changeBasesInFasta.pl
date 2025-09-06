#!/usr/bin/perl

# changeBasesInFasta.pl
# written by Linnéa Smeds                      14 Juni 2013
# =========================================================
# Takes a fasta and a list with changes (deletions, inserts
# and single base changes) which is based on the output 
# from samtools pileup (but modified first!) and infer the
# changes in the fasta sequence.
#
# The list should have the format:
# Name	Pos	Base	Change_base	Type	#Comment
# For example:
# scaffold1	140	A	C	change #
# scaffold1	201	*	T	delete_after	#
#
# for insertions and deletions, the third column should
# have an asterisk, and the inserted or removed base(s) 
# should be in column 4. The positions for these events are
# always reported as the position right BEFORE the event 
# (even for deletions! If pos 200 should be removed, write
# 199 in the second column).
# =========================================================


use strict;
use warnings;

# Input parameters
my $FASTA = $ARGV[0];
my $LIST = $ARGV[1];
my $OUTPUT = $ARGV[2];

open(OUT, ">$OUTPUT");

my $add_cnt = 0;
my $delete_cnt = 0;
my $change_cnt = 0;

# Go through the fasta (may include several sequences)
open(IN, $FASTA);
while(<IN>) {
	if($_ =~ m/^>/) {
		my $head = $_;
		my $seq = "";
		chomp($head);
		$head=~s/>//;
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

		# Sequence is saved in array with one base per index
		my @seqs = split("", $seq);
	
		print "Saved ".scalar(@seqs)." in sequence array for $head\n";

		# Go through the list
		open(LIST, $LIST);
		while(my $list=<LIST>) {
			chomp($list);
			my @col=split(/\t/, $list);

			# Only look at rows where the sequence name matches
			if($head eq $col[0]) {
				my $pos=$col[1]-1;
				
				#Three different types of changes:
				# Single change
				if($col[4] eq "change") {
					unless($seqs[$pos] eq $col[2]) {
						print "ERROR CHANGE: $head at ".$col[1].", listed as ".$col[2]." but is ".$seqs[$pos]."\n";
					}
					$seqs[$pos]=$col[3];
					$change_cnt++;
				}
				# Insertion
				elsif($col[4] eq "add_after") {
					$seqs[$pos]=$seqs[$pos].$col[3];
					$add_cnt+=length($col[3]);
				}
				# Deletion
				elsif($col[4] eq "delete_after") {
					my @del = split("", $col[3]);
					$delete_cnt+=length($col[3]);

 					for (my $i=0; $i<scalar(@del); $i++) {
						my $tmp=$pos+$i+1;
				
						unless($del[$i] eq $seqs[$tmp]) {
							print "ERROR DELETE: $head at ".$col[1].", listed as ".$col[2]." but is ".$seqs[$pos]."\n";
						}
						$seqs[$tmp]="";
					}
				}
				else {
					die "ERROR: Badly formed type ".$col[4]." on line $list\n";
				}
			}
		}
		close(LIST);

		my $newseq = join("", @seqs);
		my @blocks = split(/(.{80})/i, $newseq);
		print OUT ">".$head."\n";
		foreach my $b (@blocks) {
			if($b ne "") {
				print OUT "$b\n";
			}
		}

	}
}
close(IN);
close(OUT);

print "$change_cnt bases were changed, $add_cnt bases were added and $delete_cnt bases were deleted\n";
