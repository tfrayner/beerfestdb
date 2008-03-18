#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

package BeerFestDB::Loader;

use Text::CSV_XS;
use Readonly;
use Carp;
use Class::Std;

use BeerFestDB::ORM;
use BeerFestDB::Config qw($CONFIG);

my %schema : ATTR( :name<schema>, :default<undef> );

sub START {

    my ( $self, $id, $args ) = @_;

    unless ( $self->get_schema() ) {
	croak("Error: schema not set.");
    }

    return;
}

# Constants used throughout to label data columns. The actual numbers
# here are arbitrary; they only have to be unique.
Readonly my $UNKNOWN_COLUMN            => 0;
Readonly my $FESTIVAL_YEAR             => 1;
Readonly my $FESTIVAL_DESCRIPTION      => 2;
Readonly my $BAR_DESCRIPTION           => 3;
Readonly my $BREWER_NAME               => 4;
Readonly my $BREWER_LOC_DESC           => 5;
Readonly my $BREWER_YEAR_FOUNDED       => 6;
Readonly my $BREWER_COMMENT            => 7;
Readonly my $BEER_NAME                 => 8;
Readonly my $BEER_STYLE                => 9;
Readonly my $BEER_DESCRIPTION          => 10;
Readonly my $BEER_COMMENT              => 11;
Readonly my $GYLE_BREWERY_NUMBER       => 12;
Readonly my $GYLE_ABV                  => 13;
Readonly my $GYLE_PINT_PRICE           => 14;
Readonly my $GYLE_COMMENT              => 15;
Readonly my $DISTRIBUTOR_NAME          => 16;
Readonly my $DISTRIBUTOR_LOC_DESC      => 17;
Readonly my $DISTRIBUTOR_YEAR_FOUNDED  => 18;
Readonly my $DISTRIBUTOR_COMMENT       => 19;
Readonly my $CASK_SIZE                 => 20;
Readonly my $CASK_PRICE                => 21;
Readonly my $CASK_COMMENT              => 22;
Readonly my $CASK_MEASUREMENT_DATE     => 23;
Readonly my $CASK_MEASUREMENT_VOLUME   => 24;
Readonly my $CASK_MEASUREMENT_COMMENT  => 25;

########
# SUBS #
########

sub get_csv_parser : PRIVATE {

    my ( $self ) = @_;

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
	    allow_loose_quotes => 1,
        }
    );

    return $csv_parser;
}

sub load_data : PRIVATE {

    my ( $self, $datahash ) = @_;

    # Each of these calls defines the column to be used from the input
    # file.
    my $festival = $self->load_festival(
	{
	    year        => $datahash->{$FESTIVAL_YEAR},
	    description => $datahash->{$FESTIVAL_DESCRIPTION},
	},
    );
    my $bar = $self->load_bar(
	{
	    description => $datahash->{$BAR_DESCRIPTION},
	},
    );

    # FIXME no addresses at this point.
    my $brewer = $self->load_company(
	{
	    name         => $datahash->{$BREWER_NAME},
	    loc_desc     => $datahash->{$BREWER_LOC_DESC},
	    year_founded => $datahash->{$BREWER_YEAR_FOUNDED},
	    comment      => $datahash->{$BREWER_COMMENT},
	},
    );
    my $beer = $self->load_beer(
	{
	    name         => $datahash->{$BEER_NAME},
	    style        => $datahash->{$BEER_STYLE},
	    description  => $datahash->{$BEER_DESCRIPTION},
	    comment      => $datahash->{$BEER_COMMENT},
	},
    );
    my $gyle = $self->load_gyle(
	{
	    brewery_number => $datahash->{$GYLE_BREWERY_NUMBER},
	    brewer         => $brewer,
	    beer           => $beer,
	    abv            => $datahash->{$GYLE_ABV},
	    pint_price     => $datahash->{$GYLE_PINT_PRICE},
	    comment        => $datahash->{$GYLE_COMMENT},
	},
    );
    my $distributor = $self->load_company(
	{
	    name         => $datahash->{$DISTRIBUTOR_NAME},
	    loc_desc     => $datahash->{$DISTRIBUTOR_LOC_DESC},
	    year_founded => $datahash->{$DISTRIBUTOR_YEAR_FOUNDED},
	    comment      => $datahash->{$DISTRIBUTOR_COMMENT},
	},
    );
    my $cask = $self->load_cask(
	{
	    brewer      => $brewer,
	    beer        => $beer,
	    gyle        => $gyle,
	    distributor => $distributor,
	    festival    => $festival,
	    size        => $datahash->{$CASK_SIZE},
	    cask_price  => $datahash->{$CASK_PRICE},
	    bar         => $bar,
	    comment     => $datahash->{$CASK_COMMENT},
	},
    );
    my $cask_measurement = $self->load_cask_measurement(
	{
	    cask    => $cask,
	    date    => $datahash->{$CASK_MEASUREMENT_DATE},
	    volume  => $datahash->{$CASK_MEASUREMENT_VOLUME},
	    comment => $datahash->{$CASK_MEASUREMENT_COMMENT},
	},
    );
}

sub load_festival : PRIVATE {

    my ( $self, $args ) = @_;

    my $festival;
    if ( defined $args->{'year'} ) {

	$festival = $self->get_schema()->resultset('Festival')->find_or_create({
	    year => $args->{'year'},
	});

	if ( defined $args->{'description'} ) {
	    $festival->set_column('description' => $args->{'description'});
	}

	$festival->update();
    }

    return $festival;
}

sub load_bar : PRIVATE {

    my ( $self, $args ) = @_;

    my $bar;
    if ( defined $args->{'description'} ) {
	$bar = $self->get_schema()->resultset('Bar')->find_or_create({
	    description => $args->{'description'},
	});
    }

    return $bar;
}

sub load_company : PRIVATE {

    my ( $self, $args ) = @_;

    my $company;
    if ( defined $args->{'name'} ) {

	$company = $self->get_schema()->resultset('Company')->find_or_create({
	    name => $args->{'name'},
	});

	if ( defined $args->{'loc_desc'} ) {
	    $company->set_column('loc_desc' => $args->{'loc_desc'});
	}
	if ( defined $args->{'year_founded'} ) {
	    $company->set_column('year_founded' => $args->{'year_founded'});
	}
	if ( defined $args->{'comment'} ) {
	    $company->set_column('comment' => $args->{'comment'});
	}

	$company->update();
    }

    return $company;
}

sub load_beer : PRIVATE {

    my ( $self, $args ) = @_;

    my $beer;
    if ( defined $args->{'name'} ) {

	$beer = $self->get_schema()->resultset('Beer')->find_or_create({
	    name => $args->{'name'},
	});

	if ( defined $args->{'style'} ) {
	    $beer->set_column('style' => $args->{'style'});
	}
	if ( defined $args->{'description'} ) {
	    $beer->set_column('description' => $args->{'description'});
	}
	if ( defined $args->{'comment'} ) {
	    $beer->set_column('comment' => $args->{'comment'});
	}

	$beer->update();
    }

    return $beer;
}

sub load_gyle : PRIVATE {

    my ( $self, $args ) = @_;

    my $gyle;
    if ( defined $args->{'beer'} ) {

	$gyle = $self->get_schema()->resultset('Gyle')->find_or_create({
	    beer       => $args->{'beer'},
	    brewer     => $args->{'brewer'},
	    abv        => $args->{'abv'},
	});

	if ( defined $args->{'pint_price'} ) {
	    $gyle->set_column('pint_price' => $args->{'pint_price'});
	}
	if ( defined $args->{'brewery_number'} ) {
	    $gyle->set_column('brewery_number' => $args->{'brewery_number'});
	}
	if ( defined $args->{'comment'} ) {
	    $gyle->set_column('comment' => $args->{'comment'});
	}

	$gyle->update();
    }

    return $gyle;
}

sub load_cask : PRIVATE {

    my ( $self, $args ) = @_;

    my $cask;
    if ( defined $args->{'beer'} ) {

	$cask = $self->get_schema()->resultset('Cask')->find_or_create({
	    beer        => $args->{'beer'},
	    brewer      => $args->{'brewer'},
	    gyle        => $args->{'gyle'},
	    beer        => $args->{'beer'},
	    distributor => $args->{'distributor'},
	    festival    => $args->{'festival'},
	    bar         => $args->{'bar'},
	});

	if ( defined $args->{'size'} ) {
	    $cask->set_column('size' => $args->{'size'});
	}
	if ( defined $args->{'cask_price'} ) {
	    $cask->set_column('cask_price' => $args->{'cask_price'});
	}
	if ( defined $args->{'comment'} ) {
	    $cask->set_column('comment' => $args->{'comment'});
	}

	$cask->update();
    }

    return $cask;
}

sub load_cask_measurement : PRIVATE {

    my ( $self, $args ) = @_;

    my $cask_measurement;
    if ( defined $args->{'volume'} ) {

	$cask_measurement = $self->get_schema()->resultset('CaskMeasurement')->find_or_create({
	    cask        => $args->{'cask'},
	    date        => $args->{'date'},
	    volume      => $args->{'volume'},
	});

	if ( defined $args->{'comment'} ) {
	    $cask_measurement->set_column('comment' => $args->{'comment'});
	}

	$cask_measurement->update();
    }

    return $cask_measurement;
}

sub coerce_headings : PRIVATE {

    my ( $self, $headings ) = @_;

    my %map = (
        qr/festival [_ -]* year/ixms                   => $FESTIVAL_YEAR,
        qr/festival [_ -]* description/ixms            => $FESTIVAL_DESCRIPTION,
        qr/bar [_ -]* description/ixms                 => $BAR_DESCRIPTION,
        qr/brewer [_ -]* name/ixms                     => $BREWER_NAME,
        qr/brewer [_ -]* loc [_ -]* desc/ixms          => $BREWER_LOC_DESC,
        qr/brewer [_ -]* year [_ -]* founded/ixms      => $BREWER_YEAR_FOUNDED,
        qr/brewer [_ -]* comment/ixms                  => $BREWER_COMMENT,
        qr/beer [_ -]* name/ixms                       => $BEER_NAME,
        qr/beer [_ -]* style/ixms                      => $BEER_STYLE,
        qr/beer [_ -]* description/ixms                => $BEER_DESCRIPTION,
        qr/beer [_ -]* comment/ixms                    => $BEER_COMMENT,
        qr/gyle [_ -]* brewery [_ -]* number/ixms      => $GYLE_BREWERY_NUMBER,
        qr/gyle [_ -]* abv/ixms                        => $GYLE_ABV,
        qr/gyle [_ -]* pint [_ -]* price/ixms          => $GYLE_PINT_PRICE,
        qr/gyle [_ -]* comment/ixms                    => $GYLE_COMMENT,
        qr/distributor [_ -]* name/ixms                => $DISTRIBUTOR_NAME,
        qr/distributor [_ -]* loc [_ -]* desc/ixms     => $DISTRIBUTOR_LOC_DESC,
        qr/distributor [_ -]* year [_ -]* founded/ixms => $DISTRIBUTOR_YEAR_FOUNDED,
        qr/distributor [_ -]* comment/ixms             => $DISTRIBUTOR_COMMENT,
        qr/cask [_ -]* size/ixms                       => $CASK_SIZE,
        qr/cask [_ -]* price/ixms                      => $CASK_PRICE,
        qr/cask [_ -]* comment/ixms                    => $CASK_COMMENT,
        qr/cask [_ -]* measurement [_ -]* date/ixms    => $CASK_MEASUREMENT_DATE,
        qr/cask [_ -]* measurement [_ -]* volume/ixms  => $CASK_MEASUREMENT_VOLUME,
        qr/cask [_ -]* measurement [_ -]* comment/ixms => $CASK_MEASUREMENT_COMMENT,
    );

    my @new_headings;

    foreach my $heading (@$headings) {
        my @matches = grep { $heading =~ $_ } keys %map;
        if ( scalar @matches == 1 ) {
            push @new_headings, $map{ $matches[0] };
        }
        elsif ( scalar @matches > 1 ) {
            croak(qq{Error: ambiguous column heading "$heading".\n});
        }
        elsif ( scalar @matches < 1 ) {

            # FIXME maybe fix this to prompt on whether this is okay?
            carp(qq{Warning: Unrecognised column "$heading".\n});
            push @new_headings, $UNKNOWN_COLUMN;
        }
    }

    return \@new_headings;
}

sub load {

    my ( $self, $input ) = @_;

    my $csv_parser = $self->get_csv_parser();

    open( my $input_fh, '<', $input )
	or die(qq{Error opening input file "$input": $!});

    # Assume first line is the header, for now:
    my $headings = $self->coerce_headings( $csv_parser->getline($input_fh) );

    while ( my $rowlist = $csv_parser->getline($input_fh) ) {
	my %datahash;
	@datahash{ @$headings } = @$rowlist;
	$self->load_data( \%datahash );
    }
}

1;

