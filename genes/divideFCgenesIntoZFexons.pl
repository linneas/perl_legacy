#!/usr/bin/perl


# # # # # #
# divideFCgenesIntoZFexons.pl
# written by Linnéa Smeds                  16 Mars 2012
# =====================================================
# 
# =====================================================
# Usage: 
#

use strict;
use warnings;

# Input parameters
my $FCgenesFile = $ARGV[0];
my $ZFexonFile = $ARGV[1];
my $outpref = $ARGV[2];


# Save wanted genes
my %genes=();
open(IN, $FCgenesFile);
while(<IN>) {
	if($_ =~ m/^>/) {
		my @tab = split(/\|/, $_);
		$tab[0] =~ s/>//;
		$genes{$tab[0]}=1;
	}
}
close(IN);

#Go through the exon file and save
# exons from wnated genes only
my %ZFexons=();
open(IN, $ZFexonFile);
while(<IN>) {
	if($_ =~ m/^>/) {
		chomp($_);
		my @tab = split(/\|/, $_);
		$tab[0] =~ s/>//;
		if(defined $genes{$tab[0]}) {
			my $seq = "";
			my $next = <IN>;
			while ($next !~ m/^>/) {
				chomp($next);
				$seq.= $next;
				if(eof(IN)) {
					last;
				}	
				$next = <IN>;
			}
			seek(IN, -length($next), 1);

			if($tab[4] =~ m/;/) {
				my @exons = split(/;/, $tab[4]);
				print $tab[0]." has exons used ".scalar(@exons)." times; ".
							join(",", @exons)." are the same!!\n";
				$ZFexons{$tab[0]}{$exons[0]}=$seq;
			}
			else {	
				$ZFexons{$tab[0]}{$tab[4]}=$seq;	
			}
		}		
	}
}
close(IN);


#Outfiles
my $outList = $outpref.".list";
my $outSeq = $outpref.".fa";

open(OUT1, ">$outList");
open(OUT2, ">$outSeq");

open(IN, $FCgenesFile);
while(<IN>) {
	if($_ =~ m/^>/) {
		my @tab = split(/\|/, $_);
		$tab[0] =~ s/>//;
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

		my $prevend = 0;
		my $unCnt = 1;
		
		foreach my $exon (sort {$a<=>$b} keys %{$ZFexons{$tab[0]}}) {
			my $tempIn = "temp$exon.fa";
			my $tempOut = "temp$exon.align";
		
			open(TMP, ">$tempIn");
			print TMP ">".$tab[0]."_FC\n".$seq."\n";
			print TMP ">".$tab[0]."_ZF\n".$ZFexons{$tab[0]}{$exon}."\n";

			system("mafft --localpair --maxiterate 1000 $tempIn >$tempOut");

			open(ALN, $tempOut);
			my $h1 = <ALN>;
			my $a1 = "";

			my $next = <ALN>;
			while ($next !~ m/^>/) {
				chomp($next);
				$a1.= $next;
				if(eof(ALN)) {
					last;
				}	
				$next = <ALN>;
			}
			my $h2 = $next;
			my $a2 = "";
			$next = <ALN>;
			while ($next !~ m/^>/) {
				chomp($next),
				$a2.= $next;
				if(eof(ALN)) {
					last;
				}	
				$next = <ALN>;
			}
			close(ALN);

#			print "alignment is $a2";
			$a2 =~ m/^(-*)/;
#			print "gap i början: $1\n";
			my $alStart = length($1)+1;

			$a2 =~m/(-*)$/;
#			print "gap i slutet: $1\n";
			my $alEnd = length($seq)-length($1);

			print "alignments from $alStart to $alEnd\n";

			my $sub1 = substr($a1, $alStart-1, $alEnd-$alStart+1);
			my $sub2 = substr($a2, $alStart-1, $alEnd-$alStart+1);

			print "alignment strings:\n$sub1\n$sub2\n";

			if($sub1 = /-/) {
				print "there are gaps within the sequence.\n";

				if($sub1 =~ m/^(-*)/) {
					print "gaps in START\n";
					$alStart+=$1;
				}
				if ($sub1 =~m/(-*)$/) {
					print "gaps at END\n";
					$alEnd-=$1;
				}
				if($sub1 =~ m/w+(-+)w+/) {
					print "gaps in the middle\n";
					$alEnd+=$1;
				}
			}
			unless($alStart-$prevend==1) {
				my $betwnSt = $prevend+1;
				my $betwnEnd = $alStart-1;
				print OUT1 $tab[0]."\tunkwn\t".$betwnSt."\t".$betwnEnd."\n";
				print OUT2 ">".$tab[0]."|unknwn".$unCnt."\n";

				my $substr = substr($seq, $betwnSt-1, $betwnEnd-$betwnSt+1);
				my @seqParts = split(/(.{60})/, $substr);
				for my $seqs (@seqParts) {
					unless($seqs eq "") {
						print OUT2 $seqs."\n";
					}
				}
				$unCnt++;
				
			}
			print OUT1 $tab[0]."\texon".$exon."\t".$alStart."\t".$alEnd."\n";
			print OUT2 ">".$tab[0]."|exon".$exon."\n";
			my $substr = substr($seq, $alStart-1, $alEnd-$alStart+1);
				my @seqParts = split(/(.{60})/, $substr);
				for my $seqs (@seqParts) {
					unless($seqs eq "") {
						print OUT2 $seqs."\n";
					}
				}
			$prevend=$alEnd;
		}
	}
}				
close(IN);
close(OUT);
