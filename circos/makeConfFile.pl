#!/usr/bin/perl


# # # # # #
# makeConfigFile.pl
# written by Linnéa Smeds                13 June 2017
# ===================================================
# 
# ===================================================
# Usage: 

use strict;
use warnings;


# Input parameters
my $LEFTKARYO = $ARGV[0];
my $RIGHTKARYO = $ARGV[1];
my $JOINEDKARYO = $ARGV[2];
my $LINKS = $ARGV[3];
my $OUT = $ARGV[4];

# Save scaffold names
my @rightscaf=();
my @leftscaf=();
open(RIGHT, $RIGHTKARYO);
while(<RIGHT>) {
	my @tab = split(/\s+/, $_);
	push @rightscaf, $tab[2];
}

open(LEFT, $LEFTKARYO);
while(<LEFT>) {
	my @tab = split(/\s+/, $_);
	unshift @leftscaf, $tab[2];
}

open(OUT, ">$OUT");
print OUT 
"<colors>
<<include /sw/apps/circos/0.66/milou/etc/colors.conf>>
<<include /sw/apps/circos/0.66/milou/etc/brewer.conf>>
<<include /proj/b2016372/nobackup/workdir/linnea/circos/mychosencolors.newnames.conf>>
#<<include /proj/b2016372/nobackup/workdir/linnea/circos/colors.unix.conf>>
</colors>

<fonts>
<<include /sw/apps/circos/0.66/milou/etc/fonts.conf>>
</fonts>

<<include /proj/b2016372/nobackup/workdir/linnea/circos/template/ideogram.conf>>
#<<include /proj/b2016372/nobackup/workdir/linnea/circos/template/ticks.conf>>

<image>
<<include /sw/apps/circos/0.66/milou/etc/image.conf>>
</image>
	
";

print OUT "karyotype   = $JOINEDKARYO\n";

print OUT "\nchromosomes_units           = 80000\n";

print OUT "\n# to explicitly define what is drawn\n";

print OUT "chromosomes = ".join(";", @rightscaf).";".join(";", @leftscaf).";\n";
print OUT "chromosomes_reverse = ".join(";", @leftscaf).";\n";
print OUT "chromosomes_order = ^,".join(",", @rightscaf).",|,".join(",", @leftscaf).",\$\n"; 

print OUT "\nchromosomes_display_default = yes

chromosomes_radius = hs1:0.9r;a:0.9r;d:0.2r

<links>
z      = 0
radius = 0.99r
crest  = 1
color  = grey_a3
bezier_radius        = 0.2r
bezier_radius_purity = 0.5

<link segdup>\n";

print OUT "file             = $LINKS\n";

print OUT "ribbon           = yes
#flat             = yes
#stroke_color     = vdgrey
#stroke_thickness = 1

#<rules>
#<rule>
#importance = 100
#condition  = 1
#z = eval( scalar min(_SIZE1_,_SIZE2_) )
#color = eval( _color_ .\"_a3\")
#</rule>
#</rules>

</link>
</links>

<<include /sw/apps/circos/0.66/milou/etc/housekeeping.conf>>

";

