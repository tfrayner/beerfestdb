#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2015 Tim F. Rayner
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

use Data::Dumper;

################################################################################

package AllergenLoader;

use Moose;
use Text::CSV_XS;

has 'database'    => ( is       => 'ro',
                       isa      => 'DBIx::Class::Schema',
                       required => 1 );

has '_csv_parser' => ( is       => 'rw',
                       isa      => 'Text::CSV_XS',
                       required => 0 );

has '_header'     => ( is       => 'rw',
                       isa      => 'ArrayRef',
                       required => 0 );

# Hashref with keys as BeerFestDB::ORM class names and values as
# booleans indicating whether new objects are to be created or not.
has 'category'        => ( is       => 'rw',
                           isa      => 'Str',
                           default  => 'beer' );

has 'unprotected'     => ( is       => 'rw',
                           isa      => 'HashRef',
                           default  => sub { {} } );

has 'force_products'  => ( is       => 'rw',
                           isa      => 'Bool',
                           default  => 0,
                           trigger  => sub {
                               my ( $self, $val ) = @_;
                               $self->unprotected->{'Product'} = $val } );

has 'force_companies' => ( is       => 'rw',
                           isa      => 'Bool',
                           default  => 0,
                           trigger  => sub {
                               my ( $self, $val ) = @_;
                               $self->unprotected->{'Company'} = $val });

has 'force_allergens' => ( is       => 'rw',
                           isa      => 'Bool',
                           default  => 0,
                           trigger  => sub {
                               my ( $self, $val ) = @_;
                               $self->unprotected->{'ProductAllergenType'} = $val });

has 'interactive'     => ( is       => 'rw',
                           isa      => 'Bool',
                           default  => 0 );

sub value_acceptable {

    my ( $value ) = @_;

    if ( defined $value &&
             ( $value eq q{} ||
              $value =~ /\A (0|1|y(?:es)?|n(?:o)?|n\/?[ad]) \z/ixms ) ) {
        return 1;
    }

    return;
}

sub _parse_value {

    my ( $self, $value ) = @_;

    if ( $value eq q{} || $value =~ /\A n\/?[ad] \z/ixms ) {
        return;
    }
    elsif ( $value =~ /\A (0|n(?:o)?) \z/ixms ) {
        return 0;
    }
    elsif ( $value =~ /\A (1|y(?:es)?) \z/ixms ) {
        return 1;
    }
    else {
        die(qq{Unable to parse value "$value"\n});
    }
}

sub _parse_row {

    # Can only be called successfully once self._header is set.

    my ( $self, $larry ) = @_;

    # Parse product/company name and convert allergen presence data
    # into 0/1.
    my @rowvals = map { $_ =~ s/\A \s*(.*?)\s* \z/$1/xms; $_ } @$larry;

    my %datahash;
    @datahash{ @{ $self->_header } } = @rowvals;

    my ( $prodname, $compname, %allergen );
    while ( my ( $heading, $value ) = each %datahash ) {
        if ( $heading =~ /\A product|beer \z/ixms ) {
            $prodname = $value;
        }
        elsif ( $heading =~ /\A company|brewery? \z/ixms ) {
            $compname = $value
        }
        else {
            $allergen{ $heading } = $self->_parse_value( $value );
        }
    }

    return( $prodname, $compname, \%allergen );
}

sub _forced_creation {

    my ( $self, $dbclass ) = @_;

    return $self->unprotected->{ $dbclass };
}

sub _user_approved {

    my ( $self, $dbclass, $attrs ) = @_;

    my $decision;

    DECISION:
    {
        warn("Need to create a new $dbclass:\n");
        while ( my ( $key, $val ) = each %$attrs ) {
            warn("$key : $val\n"); # FIXME this needs to drill down into db objs.
        }
        warn("Do you approve (Y/N; N will abort load)?\n");
        chomp($decision = <STDIN>);
        redo DECISION unless ( $decision =~ /\A [yn] \z/ixms );
    }

    return lc($decision) eq 'y';
}

sub _protected_find_or_create_database_object {

    my ( $self, $dbclass, $attrs ) = @_;

    my $obj = $self->database->resultset( $dbclass )->find( $attrs );

    if ( ! $obj ) {
        if ( $self->_forced_creation( $dbclass ) ||
                 ( $self->interactive &&
                       $self->_user_approved( $dbclass, $attrs ) ) ) {
            $obj = $self->database->resultset( $dbclass )->create( $attrs );
        }
        else {
            my $msg = qq{Error: Unable to find $dbclass in the database:\n};
            while ( my ( $attr, $val ) = each %$attrs ) {
                $msg .= qq{$attr: $val\n};
            }
            die($msg);
        }
    }

    return $obj;
}

sub _load_table_data {

    my ( $self, $fh ) = @_;

    my $product_category = $self->database->resultset("ProductCategory")->find(
        { description => $self->category } )
        or die(sprintf(qq{Unable to find the product category "%s" in the database.\n"},
                       $self->category));

    PRODUCT:
    while ( my $line = $self->_csv_parser->getline($fh) ) {

        next PRODUCT if ( $line->[0] =~ /\A \s* \#/xms );
        my ( $prodname, $compname, $allergens ) = $self->_parse_row( $line );

        my $company = $self->_protected_find_or_create_database_object(
            'Company',
            { 'name' => $compname },
        );
        my $product = $self->_protected_find_or_create_database_object(
            'Product',
            { 'name'                => $prodname,
              'company_id'          => $company,
              'product_category_id' => $product_category },
        );

        while ( my ( $allername, $present ) = each %$allergens ) {

            ## FIXME we need a pre-validation run to list what would
            ## be created.
            my $allergen = $self->_protected_find_or_create_database_object(
                'ProductAllergenType',
                { 'description' => $allername },
            );
            my $record = $self->database->resultset('ProductAllergen')->find_or_create({
                product_id               => $product->id(),
                product_allergen_type_id => $allergen->id(),
            }, { key => 'product_allergen_mapping' });
            $record->set_column('present', $present);
            $record->update();
        }
    }
}

sub load {

    my ( $self, $input ) = @_;

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
            allow_loose_quotes => 1,
        }
    );
    $self->_csv_parser( $csv_parser );

    open(my $fh, '<', $input)
        or die(qq{Error: unable to open input file "$input".\n});

    my $rawheader = $self->_csv_parser->getline($fh);
    my @header = map { $_ =~ s/\A \s*(.*?)\s* \z/$1/xms; $_ } @$rawheader;
    $self->_header( \@header );

    eval {
        $self->database->txn_do( sub { $self->_load_table_data($fh); } );
    };
    if ( $@ ) {
        die(qq{Errors encountered during load:\n\n$@});
    }
    else {

        # Check that parsing completed successfully.
        my ( $error, $mess ) = $csv_parser->error_diag();
        unless ( $error == 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
            die(sprintf(
		"Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
		$mess,
		$csv_parser->error_input()));
        }

        print("Allergen data successfully loaded.\n");
    }

    return;
}

no Moose;

################################################################################

package main;

use Getopt::Long;
use Pod::Usage;
use BeerFestDB::ORM;
use BeerFestDB::Web;

sub parse_args {

    my ( $input,
         $category,
         $force_companies,
         $force_products,
         $force_allergens,
         $interactive,
         $want_help );

    GetOptions(
	"i|input=s"       => \$input,
        "c|category=s"    => \$category,
        "force-companies" => \$force_companies,
        "force-products"  => \$force_products,
        "force-allergens" => \$force_allergens,
        "interactive"     => \$interactive,
        "h|help"          => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $input ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = BeerFestDB::Web->config();

    $category ||= 'beer';

    return( $input,
            $config,
            $category,
            $force_companies,
            $force_products,
            $force_allergens,
            $interactive );
}

my ( $input,
     $config,
     $category,
     $force_companies,
     $force_products,
     $force_allergens,
     $interactive ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $loader = AllergenLoader->new(
    database        => $schema,
    category        => $category,
    force_companies => $force_companies,
    force_products  => $force_products,
    force_allergens => $force_allergens,
    interactive     => $interactive,
);

$loader->load( $input );

__END__

=head1 NAME

load_allergens.pl

=head1 SYNOPSIS

 load_allergens.pl -i <table of allergens known present or absent>

=head1 DESCRIPTION

A script used to load allergen data on products sold at the
festival. The input format is a tab-delimited table, with a single
header line. The first two columns are supplier (brewer) and product
name (beer). Each allergen is represented by a single column (the
allergen name in the header line). The column contains one of the
following values to indicate that the allergen is present in the
product: 1, y, yes (case insensitive). The following values are used
to indicate a definite absence: 0, n, no. If the presence or absence
of the allergen cannot be established, use one of these values: na,
n/a, nd, n/d, or a blank value. All other values will raise an error.

Lines beginning with # will be treated as comments.

=head1 OPTIONS

=head2 -c, --category

The product category to use when creating new products in the
database. Default is 'beer'.

=head2 --force-companies, --force-products, --force-allergens

Force the creation of new companies, products or allergen types in the
database. The default behaviour is to only create links between
products and allergens already existing in the database. If
unrecognised (i.e., new) data are encountered then the script will
exit with an error. In such cases either these options or
--interactive (below) may be used.

=head2 --interactive

Ask the user for advice on creating new objects in the database. When
loading new allergens, products or companies you will need to use
either this option or one of the --force-* options above.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
