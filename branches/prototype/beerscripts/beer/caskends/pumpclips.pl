#!/usr/bin/perl -w

# Parse the command line options
# first one is the datafile name

if (!defined($ARGV[0])) {
    die "Error: We need a filename\n";
}

$datafile=$ARGV[0];

# Read in the data
open(DATA, $datafile) || die "Can't open $datafile: $!\n";
while(<DATA>) {
    s/\#.*//;
    chomp;
    if (length($_)>0) {
        $beers[++$#beers]=$_;
    }
}
close(DATA);

# For each beer, output a cask end sign
$lastbrewery="VOID";
for $beer (@beers) {
    ($brewery,$beername,$abv,$pintprice,$colour,$bar,$handpump)=split(/,/,$beer);
    #($brewery,$beername,$abv,$estimate,$j2,$j3,$j4,$j5,$j6,$j7,$j8,$pintprice)=split(/,/,$beer);
    #($j0,$brewery,$beername,$abv,$estimate,$j2,$j3,$j4,$j5,$j6,$j7,$j8,$j9,$j10,$pintprice)=split(/,/,$beer);
    next unless $handpump;
    next if (!defined($beername));
    next unless ($pintprice =~ /^\d/);
    $beername =~ s/\s*$//;
    next if (length($beername)<2);
    $brewery =~ s/\s*$//;
    $abv =~ s/\s*$//;
    $pintprice =~ s/[^\d.]+//;
    $halfprice=$pintprice/2;
    $halfprice = sprintf("%01.2f",($halfprice));
    $pintprice = sprintf("%01.2f",($pintprice));
    ($beerline1,$beerline2)=split(/\\/,$beername);
    if (length($brewery)<2) {
	$brewery=$lastbrewery;
    }
    $lastbrewery=$brewery;
    push @newbeers, [$brewery, $beername, $abv, $pintprice, $halfprice];
}

# the rest is based on id1.pl

$logo="festival-form.ps";
$pagewidth=595;
$pageheight=842;
$width=$pagewidth/2.3;
$height=$pageheight/2.3;
$xgap=24;
$ygap=24;
$xmargin=30;
$ymargin=50;
$scale=1.00;

$imageheight = 1095; # * 1.2;
$imagewidth = 636;

# Output a Postscript preamble
open(LOGO, $logo) || die "Can't open $logo: $!\n";
while(<LOGO>) {
    print $_;
}
close(LOGO);

print "/LogoForm /CAMRA-cambridge-beerfestival-logo-2004 /Form findresource def\n";
print "/GreyLogoForm /CAMRA-cambridge-beerfestival-logo-2004-grey /Form findresource def\n";

# Output a Postscript form for an ID1-size card
print <<EOF;
/BadgeForm <<
   /FormType 1
   /BBox [ 0 0 $width $height ]
   /Matrix matrix
    /trsmall /Times-Roman findfont 10 scalefont
    /tr12 /Times-Roman findfont 12 scalefont
    /tb12 /Times-Bold findfont 12 scalefont
    /tb16 /Times-Bold findfont 16 scalefont
    /PaintProc {
	begin
	% the festival logo as a watermark
	gsave
            % imagewidth = 1095 h 636 width = 243 h 153
            % this assumes logo aspect taller than badge aspect
            $width 2 div $height 2 div 36 sub translate
	    $height $imageheight div 2 div dup scale
            0 $imagewidth sub 2 div 0 translate
	    LogoForm execform
        grestore
	% draw a box around the form
	1 setlinewidth
         newpath 0 0 moveto $width 0 lineto $width $height lineto 0 $height
	    lineto closepath
	 stroke
EOF


$yloc=80;

{print <<EOF;
    end
  }
>> def

/person /Times-Bold findfont 20 scalefont def
/job /Times-Roman findfont 14 scalefont def
/abv /Times-Roman findfont 12 scalefont def
/number /Times-Roman findfont 8 scalefont def

%%EndProlog
%%BeginSetup
<< /PageSize [ $pagewidth $pageheight ] /ImagingBBox null >> setpagedevice
%%EndSetup
EOF
}

$page=1;
I: for ($i=0; ; $i++) {
    print "%%Page: $page $page\n";
    print "$scale $scale scale\n";
    for ($y=0; $ymargin+(($height+$ygap)*$y)+$height < $pageheight; $y++) {
	for ($x=0; $xmargin+(($width+$xgap)*$x)+$width < $pagewidth; $x++) {
	    $number=$basenum++;
            last I if $number >= @newbeers;
	    $xloc=$xmargin+(($width+$xgap)*$x);
	    $yloc=$ymargin+(($height+$ygap)*$y);
	    print "gsave $xloc $yloc translate BadgeForm execform\n";
        my ($brewery, $beer, $abv, $price) = @{$newbeers[$number]};
        print <<EOF;
	gsave
	    job setfont
	    ($brewery) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 120
            moveto show
        grestore
	gsave
	    person setfont
	    ($beer) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 80
            moveto show
        grestore
	gsave
	    abv setfont (ABV: $abv%) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 40
            moveto show
        grestore
	% gsave
	%     abv setfont
	%     ($price) dup stringwidth pop
	%     $width exch sub 20 sub
        %     40
        %     moveto show
        % grestore
EOF
	    print "grestore\n";
	}
    }
    print "showpage\n";
    $page=$page+1;
}
print "%%EOF\n";



# now do labels for staff side

$width=3*72+(3*72/8);
$height=2*72+72/8;
#$width=$pagewidth/2.3;
$height=$pageheight/5;

open (LABELS, ">pumplabels.ps") or die "can't open pumplabels.ps: $!\n";
select LABELS;

print <<EOF;
%!PS-Adobe-3.0
%%Creator: 
%%Title: Cambridge Winter Ale Festival 2002
%%CreationDate: Thu Nov 22 13:12:09 2001
%%DocumentData: Clean7Bit
%%LanguageLevel: 2
%%Pages: (atend)
%%EndComments
%%BeginProlog


/person /Times-Bold findfont 20 scalefont def
/job /Times-Bold findfont 14 scalefont def
/abv /Times-Roman findfont 12 scalefont def
/number /Times-Roman findfont 8 scalefont def

%%EndProlog
%%BeginSetup
<< /PageSize [ $pagewidth $pageheight ] /ImagingBBox null >> setpagedevice
%%EndSetup
EOF

$page=1;
$basenum = 0;
I: for ($i=0; ; $i++) {
    print "%%Page: $page $page\n";
    print "$scale $scale scale\n";
    for ($y=0; $ymargin+(($height+$ygap)*$y)+$height < $pageheight; $y++) {
	for ($x=0; $xmargin+(($width+$xgap)*$x)+$width < $pagewidth; $x++) {
	    $number=$basenum++;
            last I if $number >= @newbeers;
	    $xloc=$xmargin+(($width+$xgap)*$x);
	    $yloc=$ymargin+(($height+$ygap)*$y);
#	    print "gsave $xloc $yloc translate BadgeForm execform\n";
	    print "gsave $xloc $yloc translate\n";
        my ($brewery, $beer, $abv, $price, $halfprice) = @{$newbeers[$number]};
        print <<EOF;
	gsave
	    job setfont
	    ($brewery) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 120
            moveto show
        grestore
	gsave
	    person setfont
	    ($beer) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 100
            moveto show
        grestore
	gsave
	    abv setfont (£$price / pint) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 80
            moveto show
        grestore
	gsave
	    abv setfont (£$halfprice / half) dup stringwidth
	    exch 2 div $width 2 div exch sub
	    exch pop 60
            moveto show
        grestore

%	 gsave
%	     abv setfont
%	     (£$price) dup stringwidth pop
%	     $width exch sub 20 sub
 %            60
 %            moveto show
 %        grestore
       gsave
         job setfont (NOZZLES MUST NOT TOUCH) 32 25 moveto show
         job setfont (THE BEER OR THE GLASS) 35 10 moveto show
       grestore

EOF
	    print "grestore\n";
	}
    }
    print "showpage\n";
    $page=$page+1;
}

print "showpage\n";
print "%%EOF\n";

