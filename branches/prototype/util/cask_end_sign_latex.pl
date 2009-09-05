#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use BeerFestDB::Common qw(connect_db);
use Scalar::Util qw(looks_like_number);
use Template;

sub print_latex {

    my ( $casks, $fh, $templatefile, $logofile ) = @_;

    my @casks;
    foreach my $cask ( @{ $casks } ) {
        my %caskdata;
	$caskdata{brewery} = $cask->gyle()->brewer()->name();
	$caskdata{beer}    = $cask->gyle()->beer()->name();
	$caskdata{abv}     = $cask->gyle()->abv();
	$caskdata{price}   = $cask->gyle()->pint_price() || 'STAFF';
        if ( looks_like_number( $caskdata{price} ) ) {
            $caskdata{half_price} = $caskdata{price} / 2;
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

my @casks  = $schema->resultset('Cask')->all();

print_latex( \@casks, \*STDOUT, $templatefile, $logofile );
