#!/usr/bin/perl


# # # # # #
# makeLinkAndGRIMMfromChrList.pl
# written by Linnéa Smeds                    Nov 2012
# ===================================================
# Takes anchorfiles and a reference species karyotype
# and makes link files and grimm-input for all chrom
# in a given list.
# ===================================================
# Usage: perl makeLinkAndGRIMMfromChrList.pl <CHRLIST> \
#		<REF_KARYO> <ALL_LINKED_FILE> <tg/gg> \
#		<_step.anchors>

use strict;
use warnings;


# Input parameters
my $CHROMLIST = $ARGV[0];
my $KARYOTYPE = $ARGV[1];
my $SCAFLIST = $ARGV[2]; 
my $SP = $ARGV[3];
my $FILESUFFIX = $ARGV[4];
my $special = $ARGV[5];

unless($special) {
	$special = "no";
}			

#Other parameters
my $PATH = "/bubo/home/h14/linnea/private/scripts/";

open(IN, $CHROMLIST);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);
	$chrom =~ m/chr(.+)/;
	my $chrNo = $1;

	my $karyoFile = "karyo.$chrom.col.comb.txt";
	my $linkFile = "links.$chrom.txt";
	my $grimmFile = "grimm.$chrom.txt";

	print "looking at chrom $chrNo\n";
	
	#Create karyotype
	if(($chrom eq "chr1" || $chrom eq "chr4") && $SP eq "gg" && $special eq "no") {
		my $match = "Chr".$chrNo."A";
		#Chromosome colors
		#system("awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\" ){if(NR>24){n=NR-24}else{n=NR}; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" chr\"n}' $SCAFLIST >temp");
		#Bright colors: (also change makeCircosFromChrList to include colors.mine2numbers.conf)
		system("awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\" ){if(NR>32){n=NR-32}else{n=NR}; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col\"n}' $SCAFLIST >temp");
		#One color:
		#system("awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\" ){print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col20\"}' $SCAFLIST >temp");
		#One color in scale:
		#my $rownum = `awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\"){print}' $SCAFLIST|wc -l |awk '{print \$1}'`;
		#chomp($rownum);
		#system("awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\" ){n=int((NR-1)*(240/$rownum)); print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" bluecol\"n}' $SCAFLIST >temp")

		#Replaced this:	
		#Random colors:	
		#system("awk '(\$1==\"Chr$chrNo\" ||\$1==\"$match\" ){n=int(rand()*630)+1; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col\"n}' $SCAFLIST >temp");
	}
	else {
		#Chromosome colors
		#system("awk -v n=1 '(\$1==\"Chr$chrNo\"){if(n>24){n=n-24}; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" chr\"n; n++}' $SCAFLIST >temp");
		# Bright colors:(also change makeCircosFromChrList to include colors.mine2numbers.conf)
		system("awk -v n=1 '(\$1==\"Chr$chrNo\"){if(n>32){n=n-32}; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col\"n; n++}' $SCAFLIST >temp");
		#One color:
		#system("awk '(\$1==\"Chr$chrNo\"){print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col20\"}' $SCAFLIST >temp");
		#One color in scale:
		#my $rownum = `awk '(\$1==\"Chr$chrNo\"){print}' $SCAFLIST|wc -l |awk '{print \$1}'`;
		#chomp($rownum);
		#system("awk -v r=1 '(\$1==\"Chr$chrNo\"){n=int((r-1)*(240/$rownum)); print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" bluecol\"n;r++}' $SCAFLIST >temp");
		
		#Replaced this:
		#Random colors:
		#system("awk '(\$1==\"Chr$chrNo\"){n=int(rand()*630)+1; print \"chr - \"\$2\" \"\$2\" 1 \"\$3\" col\"n}' $SCAFLIST >temp");
	}
	if($chrom eq "chr1" && $SP eq "tg") {
		system("grep \"".$SP.$chrNo."b ".$chrom."B\" $KARYOTYPE |cat temp - >temp2");
		system("mv temp2 temp");
	}

	$chrNo = lc($chrNo);

	
#	if($special ne "no" && ($chrNo eq "1a" || $chrNo eq "4a")) {
#		my $tmp = $chrNo;
#		$tmp =~ s/a//;
#		system("grep \"".$SP."$tmp chr$tmp\" $KARYOTYPE |cat temp - >$karyoFile");
		#Make linkfile
#		system("perl $PATH/createLinkFile.pl chr$tmp"."$FILESUFFIX $karyoFile $SCAFLIST ".$SP.$tmp." $linkFile");

#	}
#	else {
		system("grep \"".$SP."$chrNo $chrom\" $KARYOTYPE |cat temp - >$karyoFile");
		#Make linkfile
		system("perl $PATH/linkage/createLinkFile.pl $chrom"."$FILESUFFIX $karyoFile $SCAFLIST ".$SP.$chrNo." $linkFile");
#	}
	
	#Make GRIMM output
	system("perl $PATH/linkage/makeGRIMMinput.pl $linkFile $karyoFile fa$chrNo $grimmFile");


}
