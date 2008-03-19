#!/usr/bin/env perl

use strict;
use warnings;

use BeerFestDB::Common qw(connect_db);
use Scalar::Util qw(looks_like_number);

sub print_latex {

    my ( $casks, $fh ) = @_;

    print $fh <<"HEADER";
\\documentclass[english,a4paper]{article}

\\usepackage[a4paper, landscape]{geometry}

\\usepackage[absolute]{textpos}
\\usepackage{babel}
\\usepackage{palatino}
\\usepackage{graphicx}
\\usepackage{fix-cm}
\\begin{document}

%\\hyphenpenalty=10000
%\\exhyphenpenalty=10000

HEADER

    foreach my $cask ( @{ $casks } ) {

	my $brewery = $cask->brewer()->name();
	my $beer    = $cask->beer()->name();
	my $abv     = $cask->gyle()->abv();
	my $price   = $cask->gyle()->pint_price() || 'N/A';

	# Here we run a quick check to make sure we have a meaningful
	# price.
	my ( $pint_price, $half_price );
	if ( looks_like_number( $price ) ) {
	    $pint_price = sprintf("%.2f", $price);
	    $half_price = sprintf("%.2f", $price / 2);
	}
	else {
	    $pint_price = $price;
	    $half_price = $price;
	}

	$brewery =~ s/([\&\\])/\\$1/g;
	$beer    =~ s/([\&\\])/\\$1/g;
	$abv     =~ s/\%//g;
	$half_price ||= 500;
	$pint_price ||= 1000;

	my $beer_font_size = 54;
	if ( length( $beer ) > 25 ) {
	    $beer_font_size = 44;
	}

	print $fh <<"SIGN";

\\setlength{\\TPHorizModule}{5mm}
\\setlength{\\TPVertModule}{\\TPHorizModule}
\\textblockorigin{10mm}{10mm} % start everything near the top-left corner
\\setlength{\\parindent}{0pt}

\\pagestyle{empty}

\\fontsize{54}{75}
\\selectfont
% logos
\\begin{textblock}{37}(2,1)
\\includegraphics{octfest07_fraktur.pdf}
\\end{textblock}

\\begin{textblock}{16}(35,25)
\\includegraphics{octfest-logo-lg.png}
\\end{textblock}

\\begin{textblock}{5}(5,32)
\\includegraphics{camra_logo.png}
\\end{textblock}

% beer info to be plugged in

\\begin{textblock}{40}(6,10)

$brewery

%\\vspace{5mm}
\\fontsize{$beer_font_size}{75}
\\selectfont

$beer

% \\hspace{5mm} 0.0\\%

%\\vspace{8mm}
\\fontsize{54}{75}
\\selectfont
\\end{textblock}

\\begin{textblock}{8}(42,10)
$abv \\%
\\end{textblock}
SIGN

	if (looks_like_number($price)) {

	    print $fh <<"SIGN";

\\begin{textblock}{25}(14,25)

\\pounds $pint_price Pint 

%\\hspace{15mm}

\\pounds $half_price Half

\\end{textblock}

\\null\\newpage

SIGN

	}
	else {

	    print $fh <<"SIGN";
	
\\begin{textblock}{25}(14,25)

$price

\\end{textblock}

\\null\\newpage

SIGN

	}
    }

    print $fh <<"FOOTER";
\\end{document}
FOOTER

    return;
}

########
# MAIN #
########

my $schema = connect_db();

my @casks  = $schema->resultset('Cask')->all();

print_latex( \@casks, \*STDOUT );
