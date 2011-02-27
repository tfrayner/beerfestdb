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

package BeerFestDB::Loader::RowIterator;

use Moose;
use Carp;
use Text::CSV_XS;

has 'file'        => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1 );

has 'csv_parser'  => ( is    => 'rw',
                       isa   => 'Text::CSV_XS' );

has 'header'      => ( is     => 'rw',
                       isa    => 'ArrayRef[Str]' );

has '_filehandle' => ( is       => 'rw',
                       isa      => 'Filehandle' );

sub BUILD {

    my ( $self, $params ) = @_;

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
	    allow_loose_quotes => 1,
        }
    );

    $self->csv_parser( $csv_parser );

    open( my $fh, '<', $self->file() )
        or die("Unable to open input file: $!\n");
    $self->_filehandle( $fh );

    # Scan through the file to the first non-commented line.
    my $header = $csv_parser->getline( $fh );
    HEADERLINE:
    while( join( q{}, @$header ) =~ /\A \s* #/xms ) {
        $header = $csv_parser->getline( $fh );
        last HEADERLINE unless $header;
    }

    unless( $header ) {
        croak("Unable to detect a suitable header line in file.\n");
    }

    # Strip whitespace.
    $header = [ map { $_ =~ s/\A \s* (.*?) \s* \z/$1/xms; $_ } @$header ];

    # Check for duplicated headings.
    my %count;
    foreach my $col ( @$header ) {
        $count{ $col }++;
    }
    if ( grep { $_ > 1 } values %count ) {
        croak("Header contains duplicated column names.\n");
    }
    
    $self->header( $header );

    return;
}

sub next {

    my ( $self ) = @_;

    my $csv = $self->csv_parser();
    my $fh  = $self->_filehandle();

    my $line = $csv->getline( $fh );

    BODYLINE:
    while( join( q{}, @$line ) =~ /\A \s* #/xms ) {
        $line = $csv->getline( $fh );
        last BODYLINE unless $line;
    }

    unless ( $line ) {

        # Check that parsing completed successfully.
        my ( $error, $mess ) = $csv->error_diag();
        if ( $error != 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
            die(
                sprintf(
                    "Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
                    $mess,
                    $csv->error_input(),
                ),
            );
        }
        else {
            return;  # EOF
        }
    }

    my %data;
    @data{ @{ $self->header() } } = @$line;

    return \%data;
}



package BeerFestDB::Loader;

use Moose;

use Readonly;
use Carp;

use BeerFestDB::ORM;

has 'database' => ( is       => 'ro',
                    isa      => 'DBIx::Class::Schema',
                    required => 1 );

sub load {

    my ( $self, $file ) = @_;

    my $iter = BeerFestDB::Loader::RowIterator->new( file => $file );

    while ( my $row = $iter->next() ) {
        $self->_load_data( $row );
    }

    return;
}

{

    my %used;

    sub _load_data {  # Recursive method.

        my ( $self, $row ) = @_;

    }

}

sub _check_not_null {

    my ( $self, $value ) = @_;

    return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
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

__END__

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
	: die("Error: Must have full festival info information (i.e. year)");

    my $stillage
	= $self->_check_not_null( $datahash->{$STILLAGE_LOCATION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$STILLAGE_LOCATION},
                festival_id => $festival->id,
	    },
	    'StillageLocation')
	: undef;

    my $bar
	= $self->_check_not_null( $datahash->{$BAR_DESCRIPTION} )
	? $self->_load_column_value(
	    {
		description => $datahash->{$BAR_DESCRIPTION},
                festival_id => $festival->id,
	    },
	    'Bar')
	: undef;

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
                description => $datahash->{$PRODUCT_CATEGORY} || 'beer',
            },
            'ProductCategory');

    # FIXME this is a controlled vocab so should die on invalid values.
    my $style
	= $self->_check_not_null( $datahash->{$PRODUCT_STYLE} )
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

    my $sale_price = $datahash->{$GYLE_PINT_PRICE} ? $datahash->{$GYLE_PINT_PRICE} * 100 : undef;

    my $nominal_abv = $datahash->{$PRODUCT_ABV};
    $nominal_abv = undef if ( defined $nominal_abv && $nominal_abv eq q{} );
    my $product
	= $self->_check_not_null( $datahash->{$PRODUCT_NAME} )
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

    my $gyle
	= $festival_product
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

    my $cask_price = $datahash->{$CASK_PRICE}      ? $datahash->{$CASK_PRICE}      * 100 : undef;

    my $count = $datahash->{$CASK_COUNT};
    unless ( defined $count && $count ne q{} ) {
        $count = 1;
    }

    # We need to support adding casks in multiple loads; cask count
    # becomes an issue so we check against the database here.
    my $preexist = 0;
    if ( $gyle ) { 
	$preexist = $gyle->search_related(
	    'casks',
	    { 'festival_id' => $festival->id })->count();
	$count += $preexist;
    }

    foreach my $n ( ($preexist+1)..$count ) {

        my $cask
            = $product
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

sub _load_column_value {

    my ( $self, $args, $class, $trigger ) = @_;

    my $resultset = $self->database()->resultset($class)
	or confess(qq{Error: No result set returned from DB for class "$class".});

    foreach my $key ( keys %$args ) {
        delete $args->{$key} if ( ! defined $args->{$key} || $args->{$key} eq q{} );
    }

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

    # Create an object in the database.
    my $object = $resultset->update_or_create($args);

    return $object;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;

