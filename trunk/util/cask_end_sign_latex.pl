#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use BeerFestDB::Common qw(connect_db);
use Scalar::Util qw(looks_like_number);
use Template;
use POSIX qw(ceil);

sub format_price {

    my ( $price, $format ) = @_;

    return 'STAFF' unless $price;

    my @digits = split //, $price;

    my $formatted = q{};

    POS:
    foreach my $pos ( 1..length($format) ) {
        my $f = substr($format, -$pos, 1);
        if ( $f !~ /[#0]/ ) {
            $formatted = $f . $formatted;
            next POS;
        }
        my $num = pop @digits;
        last POS if ( $f eq '#' && ! defined $num );
        if ( $f eq '0' ) {
            $num ||= 0;
            $formatted = $num . $formatted;
        }
        else {
            die(qq{Error: Unrecognised formatting symbol: "$f".\n});
        }
    }

    return $formatted;
}

sub print_latex {

    my ( $casks, $fh, $templatefile, $logofile ) = @_;

    my @casks;
    foreach my $cask ( @{ $casks } ) {
        my %caskdata;
	$caskdata{brewery} = $cask->gyle_id()->company_id()->name();
	$caskdata{beer}    = $cask->gyle_id()->product_id()->name();
	$caskdata{abv}     = $cask->gyle_id()->abv();

        $caskdata{sale_volume} = $cask->sale_volume_id()->sale_volume_description();

        my $currency = $cask->currency_code();
        my $format   = $currency->currency_format();
        $caskdata{currency} = $currency->currency_symbol();

	$caskdata{price}   = format_price( $cask->sale_price(), $format );
        if ( looks_like_number( $caskdata{price} ) ) {
            $caskdata{half_price} = format_price( ceil($cask->sale_price() / 2), $format );
        }
        else {
            $caskdata{half_price} = $caskdata{price};
        }

        push @casks, \%caskdata;
    }

    my $vars = {
        logo  => $logofile,
        casks => \@casks,
    };

    my $template = Template->new()
        or die( "Cannot create Template object: " . Template->error() );

    $template->process($templatefile, $vars, $fh)
        or die( "Template processing error: " . $template->error() );

    return;
}

########
# MAIN #
########

my ( $templatefile, $logofile );
GetOptions(
    "t|template=s" => \$templatefile,
    "l|logo=s"     => \$logofile,
);

$templatefile ||= 'cask_end_template.tt2';

my $schema = connect_db();

# FIXME just retrieve the casks for the festival in question.
my @casks  = $schema->resultset('Cask')->all();

print_latex( \@casks, \*STDOUT, $templatefile, $logofile );
