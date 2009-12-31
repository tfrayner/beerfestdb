#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

package BeerFestDB::Loader;

use Moose;

use Text::CSV_XS;
use Readonly;
use Carp;

use BeerFestDB::ORM;

has 'database' => ( is       => 'ro',
                    isa      => 'DBIx::Class::Schema',
                    required => 1 );

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
Readonly my $CASK_COUNT                => 20;
Readonly my $CASK_SIZE                 => 21;
Readonly my $CASK_PRICE                => 22;
Readonly my $CASK_COMMENT              => 23;
Readonly my $CASK_MEASUREMENT_DATE     => 24;
Readonly my $CASK_MEASUREMENT_VOLUME   => 25;
Readonly my $CASK_MEASUREMENT_COMMENT  => 26;
Readonly my $FESTIVAL_NAME             => 27;

########
# SUBS #
########

sub _get_csv_parser {

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

sub _check_not_null {

    my ( $self, $value ) = @_;

    return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
}

sub _link_bar_and_festival {

    my ( $self, $bar, $festival ) = @_;

    my $resultset = $self->database()->resultset('FestivalBar')
	or confess(qq{Error: No result set returned from DB for class "FestivalBar".});

    $resultset->find_or_create({
        festival_id => $festival->id,
        bar_id      => $bar->id,
    });

    return;
}

sub _load_data {

    my ( $self, $datahash ) = @_;

    # Each of these calls defines the column to be used from the input
    # file.
    my $festival
	= $self->_check_not_null( $datahash->{$FESTIVAL_YEAR} )
	? $self->_load_column_value(
	    {
		year        => $datahash->{$FESTIVAL_YEAR},
		name        => $datahash->{$FESTIVAL_NAME},
                description => $datahash->{$FESTIVAL_DESCRIPTION},
	    },
	    'Festival')
	: undef;

    my $bar
	= $self->_check_not_null( $datahash->{$BAR_DESCRIPTION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$BAR_DESCRIPTION},
	    },
	    'Bar')
	: undef;

    if ( $bar && $festival ) {
        $self->_link_bar_and_festival( $bar, $festival );
    }

    # FIXME no addresses at this point.
    my $brewer
	= $self->_check_not_null( $datahash->{$BREWER_NAME} )
	? $self->_load_column_value(
	    {
		name         => $datahash->{$BREWER_NAME},
		loc_desc     => $datahash->{$BREWER_LOC_DESC},
		year_founded => $datahash->{$BREWER_YEAR_FOUNDED},
		comment      => $datahash->{$BREWER_COMMENT},
	    },
	    'Company')
	: undef;

    my $category
        = $self->_load_column_value(
            {
                description => 'beer',
            },
            'ProductCategory');

    # FIXME this is a controlled vocab so should die on invalid values.
    my $style
	= $self->_check_not_null( $datahash->{$BEER_STYLE} )
	? $self->_load_column_value(
	    {
                product_category_id => $category,
		description         => $datahash->{$BEER_STYLE},
	    },
	    'ProductStyle')
	: undef;

    my $beer
	= $self->_check_not_null( $datahash->{$BEER_NAME} )
	? $self->_load_column_value(
	    {
		name             => $datahash->{$BEER_NAME},
		description      => $datahash->{$BEER_DESCRIPTION},
		comment          => $datahash->{$BEER_COMMENT},
                product_category_id => $category,
                product_style_id    => $style,
	    },
	    'Product')
	: undef;

    my $gyle
	= $beer
	? $self->_load_column_value(
	    {
		external_reference => $datahash->{$GYLE_BREWERY_NUMBER},
		company_id         => $brewer,
		product_id         => $beer,
		abv                => $datahash->{$GYLE_ABV},
		comment            => $datahash->{$GYLE_COMMENT},
	    },
	    'Gyle')
	: undef;

    my $distributor
	= $self->_check_not_null( $datahash->{$DISTRIBUTOR_NAME} )
	? $self->_load_column_value(
	    {
		name         => $datahash->{$DISTRIBUTOR_NAME},
		loc_desc     => $datahash->{$DISTRIBUTOR_LOC_DESC},
		year_founded => $datahash->{$DISTRIBUTOR_YEAR_FOUNDED},
		comment      => $datahash->{$DISTRIBUTOR_COMMENT},
	    },
	    'Company')
	: undef;

    # This is going to be pretty much constant for UK beers. Will need
    # modification for European casks though FIXME.
    my $cask_measure = $self->_load_column_value(
        {
            litre_multiplier => 4.54609188,
            description      => 'gallon',
        },
        'ContainerMeasure');

    my $cask_size
        = $self->_check_not_null( $datahash->{$CASK_SIZE} )
        ? $self->_load_column_value(
            {
                container_volume     => $datahash->{$CASK_SIZE},
                container_measure_id => $cask_measure,
            },
            'ContainerSize')
        : undef;

    # FIXME obviously this needs to be much more sophisticated.
    my $stillage = $self->_load_column_value(
        {
            description => 'main stillage',
        },
        'StillageLocation');

    # Likely to be the default for UK beer festivals.
    my $pint_size = $self->_load_column_value(
        {
            litre_multiplier => 0.5682,
            description      => 'pint',
        },
        'ContainerMeasure');

    # FIXME why are we reiterating the description here?
    my $sale_volume = $self->_load_column_value(
        {
            container_measure_id    => $pint_size,
            sale_volume_description => 'pint',
        },
        'SaleVolume');

    # FIXME this also needs to be much more flexible (see http://en.wikipedia.org/wiki/ISO_4217).
    my $currency = $self->_load_column_value(
        {
            currency_code   => 'GBP',
            currency_number => 826,
            currency_format => '#,###,###,###,##0.00',
            exponent        => 2,
            currency_symbol => '£',
        },
        'Currency');

    my $cask_price = $datahash->{$CASK_PRICE}      ? $datahash->{$CASK_PRICE}      * 100 : undef;
    my $sale_price = $datahash->{$GYLE_PINT_PRICE} ? $datahash->{$GYLE_PINT_PRICE} * 100 : undef;

    my $count = defined $datahash->{$CASK_COUNT} ? $datahash->{$CASK_COUNT} : 1;

    foreach my $n ( 1..$count ) {

        my $cask
            = $beer
                ? $self->_load_column_value(
                    {
                        gyle_id                => $gyle,
                        distributor_company_id => $distributor,
                        festival_id            => $festival,
                        container_size_id      => $cask_size,
                        currency_code          => $currency,
                        price                  => $cask_price,
                        sale_volume_id         => $sale_volume,
                        sale_currency_code     => $currency,
                        sale_price             => $sale_price,
                        stillage_location_id   => $stillage,
                        bar_id                 => $bar,
                        comment                => $datahash->{$CASK_COMMENT},
                        internal_reference     => $n,
                    },
                    'Cask')
                    : undef;

        # FIXME at the moment we're assuming that dip measurements use the
        # same volume units as the cask sizes.
        my $cask_measurement
            = $self->_check_not_null( $datahash->{$CASK_MEASUREMENT_VOLUME} )
                ? $self->load_cask_measurement(
                    {
                        cask_id              => $cask,
                        date                 => $datahash->{$CASK_MEASUREMENT_DATE},
                        volume               => $datahash->{$CASK_MEASUREMENT_VOLUME},
                        container_measure_id => $cask_measure,
                        comment              => $datahash->{$CASK_MEASUREMENT_COMMENT},
	    },
                    'CaskMeasurement')
                    : undef;
    }

    return;
}

sub _find_required_cols {

    my ( $self, $resultset ) = @_;

    my $source = $resultset->result_source();

    my %is_pk = map { $_ => 1 } $source->primary_columns();

    my @cols = $source->columns();

    my ( @required, @optional );
    foreach my $col (@cols) {

	# FIXME we should introspect to identify primary
	# key/autoincrement columns where possible.
	next if $is_pk{ $col };
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

sub _confirm_required_cols {

    my ( $self, $args, $required ) = @_;

    my $problem;
    foreach my $col ( @{ $required } ) {
	unless ( $self->_check_not_null( $args->{$col} ) ) {
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

sub _load_column_value {

    my ( $self, $args, $class, $trigger ) = @_;

    my $resultset = $self->database()->resultset($class)
	or confess(qq{Error: No result set returned from DB for class "$class".});

    # Validate our arguments against the database.
    my ( $required, $optional ) = $self->_find_required_cols( $resultset );
    my @pk = $resultset->result_source()->primary_columns();
    my %recognised = map { $_ => 1 } @{ $required }, @{ $optional }, @pk;
    foreach my $key ( keys %{ $args } ) {
	unless ( $recognised{ $key } ) {
	    confess(qq{Error: Unrecognised column key "$key".}); 
	}
    }
    $self->_confirm_required_cols( $args, $required )
	or croak(qq{Error: Incomplete data for "$class" object.});

    # Create an object with all its required values.
    my %values = map { $_ => $args->{$_} } @{ $required };
    foreach my $k ( @pk ) {
        $values{$k} = $args->{$k} if defined $args->{$k};
    }
    my $object = $resultset->update_or_create(\%values);

    # Add in the optional values where available.
    foreach my $col ( @{ $optional } ) {
	if ( $self->_check_not_null( $args->{$col} ) ) {
	    my $value = $args->{$col};
            if ( ref $value ) {
                my @vpk = $value->result_source()->primary_columns();
                if ( scalar @vpk == 1 ) {
                    my $pcol = $vpk[0];
                    $value = $value->$pcol if ($value->can($pcol));
                }
                else {
                    die("Error: Cannot automatically link objects in tables"
                            . " with multi-column primary keys");
                }
            }
	    $object->set_column( $col => $value );
	}
    }

    $object->update();

    return $object;
}

sub _coerce_headings {

    my ( $self, $headings ) = @_;

    my %map = (
        qr/festival [_ -]* year/ixms                   => $FESTIVAL_YEAR,
        qr/festival [_ -]* name/ixms                   => $FESTIVAL_NAME,
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
        qr/cask [_ -]* (?:count|number)/ixms           => $CASK_COUNT,
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

    my $csv_parser = $self->_get_csv_parser();

    open( my $input_fh, '<', $input )
	or die(qq{Error opening input file "$input": $!});

    # Assume first line is the header, for now:
    my $headings = $self->_coerce_headings( $csv_parser->getline($input_fh) );

    while ( my $rowlist = $csv_parser->getline($input_fh) ) {
	my %datahash;
	@datahash{ @$headings } = @$rowlist;
	$self->_load_data( \%datahash );
    }
}

1;

