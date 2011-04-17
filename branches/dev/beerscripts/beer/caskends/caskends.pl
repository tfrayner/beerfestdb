#!/usr/bin/perl -w

# A script to make cask-end signs

# Configuration variables:

$logo="festival-form.ps";

# Parse the command line options
# first one is the datafile name

if (!defined($ARGV[0])) {
    die "Error: We need a filename\n";
}

$datafile=$ARGV[0];

$pageheight=595;
$pagewidth=842;

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
    my ($brewery,$beername,$abv,$pintprice,$colour)=split(/,/,$beer);
    #($brewery,$beername,$abv,$estimate,$j2,$j3,$j4,$j5,$j6,$j7,$j8,$pintprice)=split(/,/,$beer);
    #($j0,$brewery,$beername,$abv,$estimate,$j2,$j3,$j4,$j5,$j6,$j7,$j8,$j9,$j10,$pintprice)=split(/,/,$beer);
    next if (!defined($beername));
    next unless ($pintprice =~ /^\d/);
    $beername =~ s/\s*$//;
    next if (length($beername)<2);
    $brewery =~ s/\s*$//;
    $abv =~ s/\s*$//;
    $pintprice =~ s/[^\d.]+//;
    if (length($brewery)<2) {
	$brewery=$lastbrewery;
    }
    $lastbrewery=$brewery;
    $colour = lc $colour;
    $colour ||= 'nocolour';
    push @{$caskends{$colour}} , [$brewery, $beername, $abv, $pintprice];
}

foreach $colour (keys %caskends) {

open (OUT, ">output/$colour.ps") or die "can't open output/$colour.ps: $!\n";
select OUT;

# Output a Postscript preamble
open(LOGO, $logo) || die "Can't open $logo: $!\n";
while(<LOGO>) {
    print $_;
}
close(LOGO);

# A selection of fonts
print <<EOF;
/brewery /NewCenturySchlbk-Bold findfont 55 scalefont def
/beer /NewCenturySchlbk-Bold findfont 80 scalefont def
/info /NewCenturySchlbk-Bold findfont 60 scalefont def

/center { exch dup 3 1 roll sub 2 div add exch 2 div sub } bind def
%%EndProlog
%%BeginSetup
<< /PageSize [ $pageheight $pagewidth ] /ImagingBBox null >> setpagedevice
%%EndSetup
EOF

$leftmargin=20;
$rightmargin=20;
$topmargin=50;
$bottommargin=50;

# these need updating for each logo
$logopixels_wide=842;
$logopixels_high=843;

# make max dimension of logo 140 points
if ($logopixels_wide > $logopixels_high) {
	$logowidth=140;
	$logoheight=$logowidth*$logopixels_high/$logopixels_wide;
} else {
	$logoheight=140;
	$logowidth=$logoheight*$logopixels_wide/$logopixels_high;
}


# For each beer, output a cask end sign
$lastbrewery="VOID";
my $page = 0;

foreach my $caskend (@{$caskends{$colour}}) {
    my ($brewery, $beername, $abv, $pintprice) = @$caskend;
    ($beerline1,$beerline2)=split(/\\/,$beername);
    next if (!defined($brewery));
    #next unless ($pintprice =~ /^\d/);
    $beername =~ s/\s*$//;
    #next if (length($beername)<2);
    $brewery =~ s/\s*$//;
    $abv =~ s/\s*$//;
    $abv =~ s/%//g;
    $pintprice =~ s/[^\d.]+//;
    if ($pintprice =~ /\d/) {
      $halfprice=$pintprice/2;
      $halfprice = sprintf("%01.2f",($halfprice));
      $pintprice = sprintf("%01.2f",($pintprice));
    }
    ($beerline1,$beerline2)=split(/\\/,$beername);
    if (length($brewery)<2) {
	$brewery=$lastbrewery;
    }
    $lastbrewery=$brewery;

    # Landscape mode
    $page=$page+1;
    print "%%Page: $page $page\n";
    print "% Page for beer: $beername\n";
    print "% Brewery: $brewery\n";
    print "% Beer: $beername\n";
    print "% ABV: $abv\n";
    print "% Price per pint: $pintprice\n";
    print "% Price per half-pint: $halfprice\n";
    print "$pageheight 0 translate 90 rotate\n";
    # The festival logo in the top-left
    print "gsave $leftmargin $pageheight $logoheight sub\n";
    print "$topmargin sub translate\n";
    print "$logowidth $logopixels_wide div dup scale\n";
    print "/CAMRA-cambridge-beerfestival-logo-2004 /Form findresource execform grestore\n";
    # The brewery name, centered
    print "gsave\n";
    print "brewery setfont ($brewery) dup stringwidth pop\n";
    print "1 exch %scale factor\n";
    print "dup 0 $pagewidth center\n"; # -> width xloc
    # If we run into the logo, center between the logo and right margin instead
    print "dup $leftmargin $logowidth add le\n"; # -> width xloc bool
    print "{pop dup $leftmargin $logowidth add $pagewidth $rightmargin sub center} if\n";
    # If the name is still too big, scale to fit
    print "dup $leftmargin $logowidth add le\n";
    print "{pop exch pop $pagewidth $rightmargin sub $leftmargin $logowidth add sub exch div\n";
    print "(width discarded) $leftmargin $logowidth add} if\n";
    # -> width xloc
    print "$pageheight $topmargin sub $logoheight 2 div sub\n";
    print "35 sub moveto pop dup scale show grestore\n";
    # The beer name, centered on the page
    print "beer setfont ($beerline1) dup stringwidth pop\n";
    print "0 $pagewidth center $pageheight $logoheight sub $topmargin sub\n";
    print "100 sub moveto show\n";
    if (defined($beerline2)) {
	print "beer setfont ($beerline2) dup stringwidth pop\n";
	print "0 $pagewidth center $pageheight $logoheight sub $topmargin sub\n";
	print "190 sub moveto show\n";
    }

    # The beer's strength
    print "info setfont (ABV: $abv%) $leftmargin $bottommargin\n";
    print "80 add moveto show\n";

    # The price
    print "info setfont\n";
    if ($abv < 10.2) {
	print "(£$pintprice/pint) $pagewidth 2 div $bottommargin\n";
	print "80 add moveto show\n";
    }
    print "(£$halfprice/half) $pagewidth 2 div $bottommargin\n";
    print "moveto show\n";

    # That's all
    print "showpage\n\n";
}

print "%%Trailer\n";
print "%%Pages: %page\n";
print "%%EOF\n";
}
exit 0;
