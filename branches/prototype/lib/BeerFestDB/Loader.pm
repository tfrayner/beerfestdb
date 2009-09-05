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

sub check_not_null : PRIVATE {

    my ( $self, $value ) = @_;

    return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
}

sub load_data : PRIVATE {

    my ( $self, $datahash ) = @_;

    # Each of these calls defines the column to be used from the input
    # file.
    my $festival
	= $self->check_not_null( $datahash->{$FESTIVAL_YEAR} )
	? $self->load_column_value(
	    {
		year        => $datahash->{$FESTIVAL_YEAR},
		description => $datahash->{$FESTIVAL_DESCRIPTION},
	    },
	    'Festival')
	: undef;

    my $bar
	= $self->check_not_null( $datahash->{$BAR_DESCRIPTION} )
	? $self->load_column_value(
	    {
		description => $datahash->{$BAR_DESCRIPTION},
	    },
	    'Bar')
	: undef;

    # FIXME no addresses at this point.
    my $brewer
	= $self->check_not_null( $datahash->{$BREWER_NAME} )
	? $self->load_column_value(
	    {
		name         => $datahash->{$BREWER_NAME},
		loc_desc     => $datahash->{$BREWER_LOC_DESC},
		year_founded => $datahash->{$BREWER_YEAR_FOUNDED},
		comment      => $datahash->{$BREWER_COMMENT},
	    },
	    'Company')
	: undef;

    my $beer
	= $self->check_not_null( $datahash->{$BEER_NAME} )
	? $self->load_column_value(
	    {
		name         => $datahash->{$BEER_NAME},
		style        => $datahash->{$BEER_STYLE},
		description  => $datahash->{$BEER_DESCRIPTION},
		comment      => $datahash->{$BEER_COMMENT},
	    },
	    'Beer')
	: undef;

    my $gyle
	= $beer
	? $self->load_column_value(
	    {
		brewery_number => $datahash->{$GYLE_BREWERY_NUMBER},
		brewer         => $brewer,
		beer           => $beer,
		abv            => $datahash->{$GYLE_ABV},
		pint_price     => $datahash->{$GYLE_PINT_PRICE},
		comment        => $datahash->{$GYLE_COMMENT},
	    },
	    'Gyle')
	: undef;

    my $distributor
	= $self->check_not_null( $datahash->{$DISTRIBUTOR_NAME} )
	? $self->load_column_value(
	    {
		name         => $datahash->{$DISTRIBUTOR_NAME},
		loc_desc     => $datahash->{$DISTRIBUTOR_LOC_DESC},
		year_founded => $datahash->{$DISTRIBUTOR_YEAR_FOUNDED},
		comment      => $datahash->{$DISTRIBUTOR_COMMENT},
	    },
	    'Company')
	: undef;

    my $cask
	= $beer
	? $self->load_column_value(
	    {
		gyle        => $gyle,
		distributor => $distributor,
		festival    => $festival,
		size        => $datahash->{$CASK_SIZE},
		cask_price  => $datahash->{$CASK_PRICE},
		bar         => $bar,
		comment     => $datahash->{$CASK_COMMENT},
	    },
	    'Cask')
	: undef;

    my $cask_measurement
	= $self->check_not_null( $datahash->{$CASK_MEASUREMENT_VOLUME} )
	? $self->load_cask_measurement(
	    {
		cask    => $cask,
		date    => $datahash->{$CASK_MEASUREMENT_DATE},
		volume  => $datahash->{$CASK_MEASUREMENT_VOLUME},
		comment => $datahash->{$CASK_MEASUREMENT_COMMENT},
	    },
	    'CaskMeasurement')
	: undef;

    return;
}

sub find_required_cols : PRIVATE {

    my ( $self, $resultset ) = @_;

    my $source = $resultset->result_source();

    my @cols = $source->columns();

    my ( @required, @optional );
    foreach my $col (@cols) {

	# FIXME we should introspect to identify primary
	# key/autoincrement columns where possible.
	next if $col eq 'id';
	my $info = $source->column_info($col);
	if ( $info->{'is_nullable'} ) {
	    push ( @optional, $col );
	}
	else {
	    push ( @required, $col );
	}
    }

    return ( \@required, \@optional );
}

sub confirm_required_cols : PRIVATE {

    my ( $self, $args, $required ) = @_;

    my $problem;
    foreach my $col ( @{ $required } ) {
	unless ( $self->check_not_null( $args->{$col} ) ) {
	    warn(qq{Warning: Required column value "$col" not present.\n});
	    $problem++;
	}
    }

    if ( $problem ) {
	return;
    }
    else {
	return 1;
    }
}

sub load_column_value : PRIVATE {

    my ( $self, $args, $class, $trigger ) = @_;

    my $resultset = $self->get_schema()->resultset($class)
	or confess(qq{Error: No result set returned from DB for class "$class".});

    # Validate our arguments against the database.
    my ( $required, $optional ) = $self->find_required_cols( $resultset );
    my %recognised = map { $_ => 1 } @{ $required }, @{ $optional };
    foreach my $key ( keys %{ $args } ) {
	unless ( $recognised{ $key } ) {
	    confess(qq{Error: Unrecognised column key "$key".}); 
	}
    }
    $self->confirm_required_cols( $args, $required )
	or croak(qq{Error: Incomplete data for "$class" object.});

    # Create an object with all its required values.
    my %values = map { $_ => $args->{$_} } @{ $required };
    my $object = $resultset->find_or_create(\%values);

    # Add in the optional values where available.
    foreach my $col ( @{ $optional } ) {
	if ( $self->check_not_null( $args->{$col} ) ) {
	    my $value = $args->{$col};
	    $value = $value->id() if (ref $value && $value->can('id'));
	    $object->set_column( $col => $value );
	}
    }

    $object->update();

    return $object;
}

sub coerce_headings : PRIVATE {

    my ( $self, $headings ) = @_;

    my %map = (
        qr/festival [_ -]* year/ixms                   => $FESTIVAL_YEAR,
        qr/festival [_ -]* description/ixms            => $FESTIVAL_DESCRIPTION,
        qr/bar [_ -]* description/ixms                 => $BAR_DESCRIPTION,
        qr/brewery? [_ -]* name/ixms                   => $BREWER_NAME,
        qr/brewery? [_ -]* loc [_ -]* desc/ixms        => $BREWER_LOC_DESC,
        qr/brewery? [_ -]* year [_ -]* founded/ixms    => $BREWER_YEAR_FOUNDED,
        qr/brewery? [_ -]* comment/ixms                => $BREWER_COMMENT,
        qr/beer [_ -]* name/ixms                       => $BEER_NAME,
        qr/beer [_ -]* style/ixms                      => $BEER_STYLE,
        qr/beer [_ -]* description/ixms                => $BEER_DESCRIPTION,
        qr/beer [_ -]* comment/ixms                    => $BEER_COMMENT,
        qr/gyle [_ -]* brewery? [_ -]* number/ixms     => $GYLE_BREWERY_NUMBER,
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
            warn(qq{Warning: Unrecognised column "$heading" will be ignored.\n});
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

