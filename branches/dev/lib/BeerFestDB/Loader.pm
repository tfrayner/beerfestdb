#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

use strict;
use warnings;

package BeerFestDB::Loader;

use Moose;

use Text::CSV_XS;
use Readonly;
use Carp;
use List::Util qw(first);

use BeerFestDB::ORM;

with 'BeerFestDB::DBHashRefValidator';

has 'database' => ( is       => 'ro',
                    isa      => 'DBIx::Class::Schema',
                    required => 1 );

has 'protected' => ( is       => 'ro',
                     isa      => 'ArrayRef',
                     required => 0,
                     default  => sub { [] } );

has 'overwrite' => ( is       => 'ro',
                     isa      => 'Bool',
                     required => 1,
                     default  => 0 );

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
Readonly my $PRODUCT_NAME              => 8;
Readonly my $PRODUCT_STYLE             => 9;
Readonly my $PRODUCT_DESCRIPTION       => 10;
Readonly my $PRODUCT_COMMENT           => 11;
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
Readonly my $PRODUCT_CATEGORY          => 28;
Readonly my $STILLAGE_LOCATION         => 29;
Readonly my $PRODUCT_ABV               => 30;
Readonly my $ORDER_BATCH_NAME          => 31;
Readonly my $ORDER_BATCH_DATE          => 32;
Readonly my $ORDER_FINALISED           => 33;
Readonly my $ORDER_RECEIVED            => 34;
Readonly my $ORDER_COMMENT             => 35;
Readonly my $CONTACT_TYPE              => 36;
Readonly my $CONTACT_FIRST_NAME        => 37;
Readonly my $CONTACT_LAST_NAME         => 38;
Readonly my $CONTACT_STREET_ADDRESS    => 39;
Readonly my $CONTACT_POSTCODE          => 40;
Readonly my $CONTACT_COUNTRY           => 41;
Readonly my $CONTACT_EMAIL             => 42;
Readonly my $CONTACT_COMMENT           => 43;
Readonly my $CONTACT_TELEPHONE         => 44;
Readonly my $BREWER_FULL_NAME          => 45;
Readonly my $DISTRIBUTOR_FULL_NAME     => 46;
Readonly my $BREWER_URL                => 47;
Readonly my $TELEPHONE_TYPE            => 48;
Readonly my $CASK_CELLAR_ID            => 49;
Readonly my $CASK_FESTIVAL_ID          => 50;
Readonly my $BREWER_REGION             => 51;

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

sub value_is_acceptable {

    my ( $self, $value ) = @_;

    return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
}

sub _load_data {

    my ( $self, $datahash ) = @_;

    # Each of these calls defines the column to be used from the input
    # file.
    my $festival
	= $self->value_is_acceptable( $datahash->{$FESTIVAL_NAME} )
	? $self->_load_column_value(
	    {
		year        => $datahash->{$FESTIVAL_YEAR},
		name        => $datahash->{$FESTIVAL_NAME},
                description => $datahash->{$FESTIVAL_DESCRIPTION},
	    },
	    'Festival')
	: undef;

    my $stillage
	= $self->value_is_acceptable( $datahash->{$STILLAGE_LOCATION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$STILLAGE_LOCATION},
                festival_id => $festival->id,
	    },
	    'StillageLocation')
	: undef;

    my $bar
	= $self->value_is_acceptable( $datahash->{$BAR_DESCRIPTION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$BAR_DESCRIPTION},
                festival_id => $festival->id,
	    },
	    'Bar')
	: undef;

    my $region
	= $self->value_is_acceptable( $datahash->{$BREWER_REGION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$BREWER_REGION},
	    },
	    'CompanyRegion')
	: undef;

    my $brewer
	= $self->value_is_acceptable( $datahash->{$BREWER_NAME} )
	? $self->_load_column_value(
	    {
		name         => $datahash->{$BREWER_NAME},
		full_name    => $datahash->{$BREWER_FULL_NAME},
		loc_desc     => $datahash->{$BREWER_LOC_DESC},
                company_region_id => $region,
		year_founded => $datahash->{$BREWER_YEAR_FOUNDED},
		url          => $datahash->{$BREWER_URL},
		comment      => $datahash->{$BREWER_COMMENT},
	    },
	    'Company')
	: undef;

    my $category
        = $self->_load_column_value(
            {
                description => $datahash->{$PRODUCT_CATEGORY} || 'beer',
            },
            'ProductCategory');

    # FIXME this is a controlled vocab so should die on invalid values.
    my $style
	= $self->value_is_acceptable( $datahash->{$PRODUCT_STYLE} )
	? $self->_load_column_value(
	    {
                product_category_id => $category,
		description         => $datahash->{$PRODUCT_STYLE},
	    },
	    'ProductStyle')
	: undef;

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
            description             => 'pint',
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

    my $sale_price = $datahash->{$GYLE_PINT_PRICE} ? $datahash->{$GYLE_PINT_PRICE} * 100 : undef;

    my $nominal_abv = $datahash->{$PRODUCT_ABV};
    $nominal_abv = undef if ( defined $nominal_abv && $nominal_abv eq q{} );
    my $product
	= $self->value_is_acceptable( $datahash->{$PRODUCT_NAME} )
	? $self->_load_column_value(
	    {
		name             => $datahash->{$PRODUCT_NAME},
                company_id       => $brewer->company_id,
		description      => $datahash->{$PRODUCT_DESCRIPTION},
		comment          => $datahash->{$PRODUCT_COMMENT},
                product_category_id => $category,
                product_style_id    => $style,
		nominal_abv         => $nominal_abv,
	    },
	    'Product')
	: undef;

    my $distributor
	= $self->value_is_acceptable( $datahash->{$DISTRIBUTOR_NAME} )
	? $self->_load_column_value(
	    {
		name         => $datahash->{$DISTRIBUTOR_NAME},
		full_name    => $datahash->{$DISTRIBUTOR_FULL_NAME},
		loc_desc     => $datahash->{$DISTRIBUTOR_LOC_DESC},
		year_founded => $datahash->{$DISTRIBUTOR_YEAR_FOUNDED},
		comment      => $datahash->{$DISTRIBUTOR_COMMENT},
	    },
	    'Company')
	: undef;

    my $contact_type
        = $self->value_is_acceptable( $datahash->{$CONTACT_TYPE} )
        ? $self->_load_column_value(
            {
                description => $datahash->{$CONTACT_TYPE},
            },
            'ContactType')
        : undef;

    ## N.B. Will fail if not already present in the database; we don't
    ## want to support all the iso2, iso3, num3 data for a simple
    ## product order load.
    my $country   
        = $self->value_is_acceptable( $datahash->{$CONTACT_COUNTRY} )
        ? $self->_load_column_value(
            {
                country_code_iso2 => $datahash->{$CONTACT_COUNTRY},
            },
            'Country')
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
        = $self->value_is_acceptable( $datahash->{$CASK_SIZE} )
        ? $self->_load_column_value(
            {
                container_volume     => $datahash->{$CASK_SIZE},
                container_measure_id => $cask_measure,
            },
            'ContainerSize')
        : undef;

    my $cask_price = $datahash->{$CASK_PRICE}      ? $datahash->{$CASK_PRICE}      * 100 : undef;

    my $count = $datahash->{$CASK_COUNT};
    unless ( defined $count && $count ne q{} ) {
        $count = 0;
    }

    my $contact_hash = {
        contact_type_id => $contact_type,
        last_name       => $datahash->{$CONTACT_LAST_NAME},
        first_name      => $datahash->{$CONTACT_FIRST_NAME},
        street_address  => $datahash->{$CONTACT_STREET_ADDRESS},
        postcode        => $datahash->{$CONTACT_POSTCODE},
        email           => $datahash->{$CONTACT_EMAIL},
        country_id      => $country,
        comment         => $datahash->{$CONTACT_COMMENT},
    };
    my $contact;

    if ( my $batchname = $datahash->{$ORDER_BATCH_NAME} ) { # ProductOrder
        my $order_batch = $self->_load_column_value(
            {
                festival_id            => $festival,
                description            => $batchname,
                order_date             => $datahash->{$ORDER_BATCH_DATE},
            },
            'OrderBatch',
        );
        my $product_order = $self->_load_column_value(
            {
                order_batch_id         => $order_batch,
                product_id             => $product,
                distributor_company_id => $distributor,
                container_size_id      => $cask_size,
                cask_count             => $count,
                currency_id            => $currency,
                advertised_price       => $cask_price,
                is_final               => $datahash->{$ORDER_FINALISED},
                is_received            => $datahash->{$ORDER_RECEIVED},
                comment                => $datahash->{$ORDER_COMMENT},
            },
            'ProductOrder',
        );
        $contact
            = $contact_type
            ? $self->_load_column_value(
                {
                    %{ $contact_hash },
                    company_id     => $distributor,
                },
                'Contact')
            : undef;
    }
    else {  # FestivalProduct
        
        my $festival_product;
        if ( $product && $festival ) {
            $festival_product = $self->_load_column_value(
                {
                    festival_id => $festival->festival_id,
                    product_id  => $product->product_id,
                    sale_volume_id      => $sale_volume,
                    sale_currency_id    => $currency,
                    sale_price          => $sale_price,
                },
                'FestivalProduct');
        }

        my $has_cask_identifiers
            = $self->value_is_acceptable( $datahash->{$CASK_CELLAR_ID} )
          || $self->value_is_acceptable( $datahash->{$CASK_FESTIVAL_ID} );

        my $gyle
            = $festival_product && ( $count || $has_cask_identifiers || $datahash->{$GYLE_ABV} )
            ? $self->_load_column_value(
                {
                    external_reference => $datahash->{$GYLE_BREWERY_NUMBER},
                    internal_reference => 'auto-generated',
                    company_id         => $brewer,
                    festival_product_id => $festival_product,
                    abv                => $datahash->{$GYLE_ABV},
                    comment            => $datahash->{$GYLE_COMMENT},
                },
                'Gyle')
            : undef;

        # We need to support adding casks in multiple loads; cask count
        # becomes an issue so we check against the database here.
        my $preexist = 0;
        if ( $gyle && $festival ) { 
            $preexist = $gyle->search_related(
                'casks',
                { 'festival_id' => $festival->id })->count();
            $count += $preexist;
        }

        my @wanted_casks = ($preexist+1)..$count;
        if ( $has_cask_identifiers ) {
            if ( scalar @wanted_casks ) {
                die("Simultaneous use of cask_count and cask identifier columns is not supported.");
            }
            @wanted_casks = $datahash->{$CASK_CELLAR_ID};
        }
        
        foreach my $n ( @wanted_casks ) {

            my $cask
                = ( $product && $festival )
                    ? $self->_load_column_value(
                        {
                            gyle_id                => $gyle,
                            distributor_company_id => $distributor,
                            festival_id            => $festival,
                            container_size_id      => $cask_size,
                            currency_id            => $currency,
                            price                  => $cask_price,
                            stillage_location_id   => $stillage,
                            bar_id                 => $bar,
                            comment                => $datahash->{$CASK_COMMENT},
                            internal_reference     => $n,
                            cellar_reference       => $datahash->{$CASK_FESTIVAL_ID},
                        },
                        'Cask')
                        : undef;

            # FIXME at the moment we're assuming that dip measurements use the
            # same volume units as the cask sizes.
            my $cask_measurement
                = $self->value_is_acceptable( $datahash->{$CASK_MEASUREMENT_VOLUME} )
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

        $contact
            = ( $contact_type && $festival_product )
            ? $self->_load_column_value(
                {
                    %{ $contact_hash },
                    company_id     => $brewer,
                },
                'Contact')
            : undef;
    }

    # If the use of contact is non-obvious, attach it to brewer preferentially.
    if ( $contact_type && ! $contact ) {
        $contact
            = $self->_load_column_value(
                {
                    %{ $contact_hash },
                    company_id     => ( $brewer || $distributor ),
                },
                'Contact');
    }

    my $phone_type
        = $self->value_is_acceptable( $datahash->{$TELEPHONE_TYPE} )
        ? $self->_load_column_value(
            {
                description => $datahash->{$TELEPHONE_TYPE},
            },
            'TelephoneType')
        : undef;

    my $telephone  ## FIXME ultimately we'll want to split into area+local.
        = ( $contact && $self->value_is_acceptable( $datahash->{$CONTACT_TELEPHONE} ) )
        ? $self->_load_column_value(
            {
                contact_id   => $contact,
                local_number => $datahash->{$CONTACT_TELEPHONE},
                telephone_type_id => $phone_type,
            },
            'Telephone')
        : undef;

    return;
}

sub _retrieve_obj_id {

    my ( $self, $obj ) = @_;

    return $obj unless ref $obj;

    $obj->id();  # Calls here will likely fail for multi-column PKs.
}

sub _load_column_value {

    my ( $self, $args, $class, $trigger ) = @_;

    my $resultset = $self->database()->resultset($class)
	or confess(qq{Error: No result set returned from DB for class "$class".});

    # Fields containing only whitespace are discarded.
    foreach my $key ( keys %$args ) {
        delete $args->{$key} if ( ! defined $args->{$key} || $args->{$key} =~ /\A \s* \z/xms );
    }

    # This would be pretty useless.
    unless ( scalar grep { defined $_ } values %$args ) {
        confess("Error: no query information for $class.");
    }

    # Validate our arguments against the database.
    $self->validate_against_resultset( $args, $resultset );
    my ( $required, $optional ) = $self->resultset_required_columns( $resultset );

    # Rather obnoxious special casing of a column which, while
    # technically optional, still confers identity when it is
    # present. The altenative seems to be to make this NOT NULL in the
    # database, which is further than I want to go.
    if ( $class eq 'Cask' && exists $args->{'cellar_reference'} ) {
        push @$required, 'cellar_reference';
        @$optional = grep { $_ ne 'cellar_reference' } @$optional;
    }

    # Create an object in the database.
    my $object;
    my %req = map { $_ => $self->_retrieve_obj_id( $args->{$_} ) } @{ $required };

    if ( first { $class eq $_ } @{ $self->protected() } ) {

        # Protected class; do not create a new row.
        my @objects = $resultset->search(\%req);
        if ( scalar @objects == 1 ) {
            $object = $objects[0];
        }
        elsif ( scalar @objects == 0 ) {
            use Data::Dumper;
            $Data::Dumper::Maxdepth = 3;
            croak(qq{Error: Object from protected class "$class" not found in}
                      . qq{ database; will not autocreate. Query dump follows: }
                          . Dumper \%req);
        }
        else {  # This is bad - it indicates a class which is not
                # uniquely defined by its required attributes.
            confess(qq{Error: Multiple objects returned from protected class "$class".});
        }
    }
    else {

        # Regular class; find and/or create as necessary.
        $object = $resultset->find_or_create(\%req);
    }

    # Update optional columns, e.g. description on Product.
    my %opt = map { $_ => $self->_retrieve_obj_id( $args->{$_} ) } @{ $optional };

    COLUMN:
    while ( my ( $col, $value ) = each %opt ) {

        next COLUMN unless defined $value;

        # Special-case for comment fields - append new text rather than replacing the old.
        if ( $col eq 'comment' ) {
            my $dbval = $object->get_column( $col );
            if ( defined $dbval && $dbval !~ /\A \s* \z/xms ) {
                next COLUMN if ( $dbval =~ /\Q$value\E/ );  # Comment already contains the text.
                $dbval =~ s/(?:\.)? \z/./xms;
                $object->set_column( $col, "$dbval $value" ) if defined $value;
            }
            else {
                $object->set_column( $col, $value ) if defined $value;
            }

            next COLUMN;
        }

        # Only overwrite old data if we've been given the green light.
        my $old = $object->get_column( $col );
        if ( ! defined $old || $old =~ /\A \s* \z/xms || $self->overwrite() ) {
            $object->set_column( $col, $value ) if defined $value;
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
        qr/stillage [_ -]* loc (?:ation)?/ixms         => $STILLAGE_LOCATION,
        qr/brewery? [_ -]* name/ixms                   => $BREWER_NAME,
        qr/brewery? [_ -]* full [_ -]* name/ixms       => $BREWER_FULL_NAME,
        qr/brewery? [_ -]* loc [_ -]* desc/ixms        => $BREWER_LOC_DESC,
        qr/brewery? [_ -]* region/ixms                 => $BREWER_REGION,
        qr/brewery? [_ -]* year [_ -]* founded/ixms    => $BREWER_YEAR_FOUNDED,
        qr/brewery? [_ -]* comment/ixms                => $BREWER_COMMENT,
        qr/brewery? [_ -]* website/ixms                => $BREWER_URL,
        qr/product [_ -]* name/ixms                    => $PRODUCT_NAME,
        qr/product [_ -]* style/ixms                   => $PRODUCT_STYLE,
        qr/product [_ -]* description/ixms             => $PRODUCT_DESCRIPTION,
        qr/product [_ -]* comment/ixms                 => $PRODUCT_COMMENT,
        qr/product [_ -]* abv/ixms                     => $PRODUCT_ABV,
        qr/gyle [_ -]* brewery? [_ -]* number/ixms     => $GYLE_BREWERY_NUMBER,
        qr/gyle [_ -]* abv/ixms                        => $GYLE_ABV,
        qr/product [_ -]* sale [_ -]* price/ixms       => $GYLE_PINT_PRICE,
        qr/gyle [_ -]* comment/ixms                    => $GYLE_COMMENT,
        qr/distributor [_ -]* name/ixms                => $DISTRIBUTOR_NAME,
        qr/distributor [_ -]* full [_ -]* name/ixms    => $DISTRIBUTOR_FULL_NAME,
        qr/distributor [_ -]* loc [_ -]* desc/ixms     => $DISTRIBUTOR_LOC_DESC,
        qr/distributor [_ -]* year [_ -]* founded/ixms => $DISTRIBUTOR_YEAR_FOUNDED,
        qr/distributor [_ -]* comment/ixms             => $DISTRIBUTOR_COMMENT,
        qr/cask [_ -]* cellar [_ -]* id/ixms           => $CASK_CELLAR_ID,
        qr/cask [_ -]* festival [_ -]* id/ixms         => $CASK_FESTIVAL_ID,
        qr/cask [_ -]* size/ixms                       => $CASK_SIZE,
        qr/cask [_ -]* price/ixms                      => $CASK_PRICE,
        qr/cask [_ -]* comment/ixms                    => $CASK_COMMENT,
        qr/cask [_ -]* measurement [_ -]* date/ixms    => $CASK_MEASUREMENT_DATE,
        qr/cask [_ -]* measurement [_ -]* volume/ixms  => $CASK_MEASUREMENT_VOLUME,
        qr/cask [_ -]* measurement [_ -]* comment/ixms => $CASK_MEASUREMENT_COMMENT,
        qr/product [_ -]* category/ixms                => $PRODUCT_CATEGORY,
        qr/order [_ -]* batch/ixms                     => $ORDER_BATCH_NAME,
        qr/order [_ -]* batch [_ -]* date/ixms         => $ORDER_BATCH_DATE,
        qr/order [_ -]* finali[sz]ed/ixms              => $ORDER_FINALISED,
        qr/order [_ -]* received/ixms                  => $ORDER_RECEIVED,
        qr/order [_ -]* comment/ixms                   => $ORDER_COMMENT,
        qr/contact [_ -]* type/ixms                    => $CONTACT_TYPE,
        qr/contact [_ -]* first [_ -]* name/ixms       => $CONTACT_FIRST_NAME,
        qr/contact [_ -]* last [_ -]* name/ixms        => $CONTACT_LAST_NAME,
        qr/contact [_ -]* street [_ -]* address/ixms   => $CONTACT_STREET_ADDRESS,
        qr/contact [_ -]* postcode/ixms                => $CONTACT_POSTCODE,
        qr/contact [_ -]* country [_ -]* iso2/ixms     => $CONTACT_COUNTRY,
        qr/contact [_ -]* email/ixms                   => $CONTACT_EMAIL,
        qr/contact [_ -]* (?:tele)? phone/ixms         => $CONTACT_TELEPHONE,
        qr/contact [_ -]* comment/ixms                 => $CONTACT_COMMENT,
        qr/telephone[_ -]* type/ixms                   => $TELEPHONE_TYPE,
    );

    my @new_headings;

    foreach my $heading (@$headings) {
        my @matches = grep { $heading =~ /\A$_\z/ms } keys %map;
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

    if ( $self->overwrite() ) {
        warn("Loader running in OVERWRITE mode.\n");
    }

    # Run the whole load in a single transaction.
    my $db = $self->database();
    eval {
        $db->txn_do(
            sub {
                while ( my $rowlist = $csv_parser->getline($input_fh) ) {
                    next if $rowlist->[0] =~ /^\s*#/;
                    my %datahash;
                    @datahash{ @$headings } = @$rowlist;
                    $self->_load_data( \%datahash );
                }
            }
        );
    };
    if ( $@ ) {
        die(qq{Errors encountered during load:\n\n$@});
    }
    else {
        warn("All data successfully loaded.\n");
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;

