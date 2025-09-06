#!/usr/bin/perl


# # # # # #
# makeCircosFromChrList.pl
# written by Linnéa Smeds                    Nov 2012
# ===================================================
# Following the script "makeLinkAndGRIMMfromChrList.pl"
# this one creates circos config files and then run 
# circos for all chromosomes in a given list.
# NOTE: Circos doesn't run on uppmax, have used this 
# script on local /media/zeus/
# ===================================================
# Usage: 

use strict;
use warnings;


# Input parameters
my $CHROMLIST = $ARGV[0];
my $SP = $ARGV[1];
my $FIGNAME = $ARGV[2];
		

# Circos files (must be place in current directory)
my $circos = "circos.conf";
my $ticks = "ticks.conf";
my $ideo = "ideogram.conf";
my $ideoPos = "ideogram.position.conf";
my $bands = "bands.conf"; 
my $ideoLab = "ideogram.label.conf";
my $ideoChr1 = "ideogram.chr1special.conf";
my $ideoChr1CH = "ideogram.chr1specialCH.conf";
my $ideoChr4CH = "ideogram.chr4specialCH.conf";


open(IN, $CHROMLIST);
while(<IN>) {
	my $chrom = $_;
	chomp($chrom);
	$chrom =~ m/chr(.+)/;
	my $chrNo = $1;

	my $linkFile = "links.$chrom.txt";
	my $karyoFile = "karyo.$chrom.col.comb.txt";
	my $dir = `pwd`;
	chomp($dir);
	my $karyoPath = $dir."/".$karyoFile;
	my $linkPath = $dir."/".$linkFile;
	
	#Creating directory
	system("mkdir -p $chrom/");

	#Copying files to the directory
	system("cp $ticks $chrom/");
	system("cp $ideoPos $chrom/");
	system("cp $bands $chrom/");
	system("cp $ideoLab $chrom/");

	#Special for chr1 and chr4
	if($chrom eq "chr1" && $SP eq "tg") {
		system("cp $ideoChr1 $chrom/$ideo");
	}
	elsif($chrom eq "chr1" && $SP eq "gg") {
		system("cp $ideoChr1CH $chrom/$ideo");
	}
	elsif($chrom eq "chr4" && $SP eq "gg") {
		system("cp $ideoChr4CH $chrom/$ideo");
	}
	# All others - change to the right name in the ideogram file
	else {
		system("cp $ideo $chrom/");
		my $tag = lc($SP.$chrNo);
		system("sed -i 's/CHANGETHIS/$tag/' $chrom/$ideo");
	}

	#Setting the scale different depeding on chr size
	my $unit = 500000;
	if($chrNo>5 && $chrNo<10 || $chrNo eq "4a") {
		$unit = 100000;
	}
	elsif ($chrNo>9 && $chrNo<15) {
		$unit = 80000;
	}
	elsif ($chrNo>14 && $chrNo<20) {
		$unit = 50000;
	}
	elsif ($chrNo>19 && $chrNo<29) {
		$unit = 25000;
	}

	#Making the circos.conf file:
	open(OUT, ">$circos");
	
	print OUT "
<colors>
<<include etc/colors.conf>>
<<include etc/colors.mine2number.conf>>
#<<include etc/colors.lsbluehue.conf>>
#<<include etc/brewer.conf>>
</colors>

<fonts>
<<include etc/fonts.conf>>
</fonts>

<<include ideogram.conf>>
#<<include ticks.conf>>

<image>
<<include etc/image.conf>>
</image>
	
karyotype   = $karyoPath;

chromosomes_units           = $unit

# to explicitly define what is drawn
";

	my $listREF = `grep $SP $karyoFile |awk '{print \$3}' |tr \"\n\", \";\"`;
	my $listQUE = `grep -v $SP $karyoFile |awk '{print \$3}' |tr \"\n\", \";\"`;

	my $list = $listREF.$listQUE;
	my $listQUErev = `grep -v $SP $karyoFile |awk '{print \$3}' |tac |tr \"\n\", \",\"`;

	$listREF =~ s/;/,/g;

	print OUT "
chromosomes = $list
chromosomes_reverse = $listQUE
chromosomes_order = ^,$listREF|,$listQUErev\$

#chromosomes_display_default = yes

chromosomes_radius = hs1:0.9r;a:0.9r;d:0.2r


<links>
z      = 0
radius = 0.99r
crest  = 1
color  = grey_a3
bezier_radius        = 0.2r
bezier_radius_purity = 0.5

<link segdup>
file             = $linkPath
ribbon           = yes
#flat             = yes
#stroke_color     = vdgrey
#stroke_thickness = 1

<rules>
<rule>
importance = 100
condition  = 1
z = eval( scalar min(_SIZE1_,_SIZE2_) )
color = eval( _color_ .\"_a3\")
</rule>
</rules>

</link>
</links>

<<include etc/housekeeping.conf>>
";

	close(OUT);
	system("mv $circos $chrom/");
	system("cd $chrom/ && ~/Program/circos-0.56/bin/circos -conf circos.conf && mv circos.svg circos.$chrom.$FIGNAME.svg && mv circos.png circos.$chrom.$FIGNAME.png && cd ..");	
#	system("mv circos.svg circos.$chrom.$FIGNAME.svg");
#	system("mv circos.png circos.$chrom.$FIGNAME.png");

}
close(IN);
