#!/usr/bin/perl


# # # # # #
# breakFastaOnSplitSites.pl
# written by Linnéa Smeds		             March 2012
# =====================================================
# 
# =====================================================
# Usage: perl 
#

use strict;
use warnings;
use List::Util qw[min max];

# Input parameters
my $listOfSplits = $ARGV[0];	 
my $assembly = $ARGV[1];
my $outpref = $ARGV[2];	

# Other parameters
my $L_column = 5;
my $R_column = 6;
my $rowlength = 100;
my $monoThres = 30;
my $lenThres = 200;

# Save splits
my %splits = ();
open(IN, $listOfSplits);
while(<IN>) {
	my @tab = split(/\s+/, $_);
	my $next_no = 1;

	unless(/^#/) {
		if(defined $splits{$tab[0]}) {
			foreach my $key (sort {$a<=>$b} keys %{$splits{$tab[0]}}) {
				$next_no = $key;
			}
			$next_no++;
		}
		$splits{$tab[0]}{$next_no}{'left'} = $tab[$L_column];
		$splits{$tab[0]}{$next_no}{'right'} = $tab[$R_column];
	
#		print "DEBUG: saving ".$tab[0]." with $next_no to ".$tab[$L_column]." ".$tab[$R_column]."\n";
	}
}
close(IN);

# Open outfile
my $FastaOut = $outpref.".fa";
open(my $fh, ">$FastaOut");
my $MapOut = $outpref.".map";
open(MAP, ">$MapOut");


# Open assembly file and split if neccessary
my $printFlag = "off";
open(IN, $assembly);
while(<IN>) {
	if(/>/) {
		my $head = $_;
		chomp($head);
		$head =~ s/>//;
		
		#If split, save sequence
		if(defined $splits{$head}) {

#			print "DEBUG: $head is found in the hash\n";
			my $seq = "";
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

			my $seqLen = length($seq);
			my ($left, $middle, $right, $tempLeft, $tempLeftStart, $oldStart, $oldEnd) = ("","","","",0,1,1);
			my $cnt=1;

			foreach my $key (sort {$a<=>$b} keys %{$splits{$head}}) {
#				print "DEBUG: splitting $head on ".$splits{$head}{$key}{'left'}." and ".$splits{$head}{$key}{'right'}."\n";

				# Overlapping sequences, split in two
				if($splits{$head}{$key}{'left'} >= $splits{$head}{$key}{'right'}) {
					if($tempLeft eq "") {
						$left = substr($seq, 0, $splits{$head}{$key}{'left'});
						$right = substr($seq, $splits{$head}{$key}{'right'}-1, $seqLen-($splits{$head}{$key}{'right'}-1));
					}
					else {
						$left = substr($tempLeft, 0, $splits{$head}{$key}{'left'}-($tempLeftStart-1));
						$right = substr($tempLeft, $splits{$head}{$key}{'right'}-$tempLeftStart, $seqLen-($splits{$head}{$key}{'right'}-1));
						my $tempstart=$splits{$head}{$key}{'right'}-$tempLeftStart;
					}
				}
				# Non-overlapping sequences, split in three
				else {
					if($tempLeft eq "") {
						$left = substr($seq, 0, $splits{$head}{$key}{'left'});
						$middle = substr($seq, $splits{$head}{$key}{'left'}, $splits{$head}{$key}{'right'}-$splits{$head}{$key}{'left'}-1);
						$right = substr($seq, $splits{$head}{$key}{'right'}-1, $seqLen-($splits{$head}{$key}{'right'}-1));
					}
					else {
						$left = substr($tempLeft, 0, $splits{$head}{$key}{'left'}-($tempLeftStart-1));
						$middle = substr($tempLeft, $splits{$head}{$key}{'left'}-$tempLeftStart, $splits{$head}{$key}{'right'}-$splits{$head}{$key}{'left'}-1);
						$right = substr($tempLeft, $splits{$head}{$key}{'right'}-$tempLeftStart, $seqLen-($splits{$head}{$key}{'right'}-1));
					}
				}
				$tempLeft = $right;
				$tempLeftStart = $splits{$head}{$key}{'right'};
				
				#Print in subroutine
				&printSeq("$head.$cnt", $left, $fh, $rowlength);
				$oldEnd = $splits{$head}{$key}{'left'};
				print MAP "$head.$cnt\t$head\t$oldStart\t$oldEnd\n";	
				$oldStart = $oldEnd+1;
				$cnt++;
				if($splits{$head}{$key}{'left'} < $splits{$head}{$key}{'right'}) {
					unless(length($middle)==0) {
			
						#Check middle part and remove mono-repeats and Ns
						my ($rmStart, $rmEnd);
						($middle, $rmStart, $rmEnd) = &checkSeq($middle, $monoThres);
			#			print "DEBUG: now middle is $middle and RM length is $rmStart and $rmEnd\n";
						print "$head: Removed $rmStart bases from start and $rmEnd bases from end of middle part\n";
						
						if(length($middle)>=$lenThres) {
							&printSeq("$head.$cnt", $middle, $fh, $rowlength);
							$oldStart = $oldStart+$rmStart;
							$oldEnd = $oldEnd+length($middle)+$rmStart;
							print MAP "$head.$cnt\t$head\t$oldStart\t$oldEnd\n";
							$cnt++;
						}
						else {
							print "Middle part of $head was too short\n";
						}
					}
				}	
				$oldStart = $splits{$head}{$key}{'right'};
			}	
			$oldEnd = $seqLen;
			&printSeq("$head.$cnt", $right, $fh, $rowlength);
			print MAP "$head.$cnt\t$head\t$oldStart\t$oldEnd\n";	

			$printFlag = "off";

		}
		else {
			$printFlag = "on";
			print $fh $_;
#			print "DEBUG: There is no $head in the hash - printing it unchanged.\n";
		}
	}
	else {
		if($printFlag eq "on") {
			print $fh $_;
		}
	}
}
close(IN);

# Subroutine that prints the split sequence
sub printSeq {
	my $head = shift;
	my $seq = shift;
	my $fh = shift;
	my $rowlen = shift;

	print $fh ">$head\n";
	my @blocks = split(/(.{$rowlen})/i, $seq);
	foreach my $b (@blocks) {
		if($b ne "") {
			print $fh "$b\n";
		}
	}	
}

# Subroutine that checks and removes Ns and mono repeats from ends of middle part
sub checkSeq {
	my $sequence = shift;
	my $repThres = shift;

	my ($start, $end) = ("","");

	if($sequence =~ m/(^N{1,})/i ||$sequence =~ m/(^A{$repThres,})/i || $sequence =~ m/(^C{$repThres,})/i ||
		$sequence =~ m/(^G{$repThres,})/i || $sequence =~ m/(^T{$repThres,})/i) {
		$start = $1;
		$sequence = substr($sequence, length($start), length($sequence)-length($start));
		}
	if($sequence =~ m/(N{1,}$)/i || $sequence =~ m/(A{$repThres,}$)/i || $sequence =~ m/(C{$repThres,}$)/i ||
		$sequence =~ m/(G{$repThres,}$)/i || $sequence =~ m/(T{$repThres,}$)/i) {
		$end = $1;
		$sequence = substr($sequence, 0, length($sequence)-length($end));
	}

	#print "Now middle looks like: $sequence\n";
	return $sequence, length($start), length($end);
}


