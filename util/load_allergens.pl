#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2013 Tim F. Rayner
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

use Getopt::Long;
use Pod::Usage;
use Text::CSV_XS;
use BeerFestDB::ORM;
use BeerFestDB::Web;

use Data::Dumper;

package AllergenLoader;

use Moose;

has 'database'    => ( is       => 'ro',
                       isa      => 'DBIx::Class::Schema',
                       required => 1 );

has '_csv_parser' => ( is       => 'rw',
                       isa      => 'Text::CSV_XS',
                       required => 0 );

has '_header'     => ( is       => 'rw',
                       isa      => 'ArrayRef',
                       required => 0 );

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

sub _load_table_data {

    my ( $self, $fh ) = @_;

    my $db = $self->database;

    PRODUCT:
    while ( my $line = $self->_csv_parser->getline($fh) ) {

        next PRODUCT if ( $line->[0] =~ /\A \s* \#/xms );
        my ( $prodname, $compname, $allergens ) = $self->_parse_row( $line );

        my $product = $db->resultset('Product')->find(
            {
                'name'            => $prodname,
                'company_id.name' => $compname,
            },
            { join => 'company_id' } )
            or die(qq{Error: Unable to find Product in the database:\n}
                       .qq{$compname: $prodname\n});

        while ( my ( $allername, $present ) = each %$allergens ) {

            ## FIXME set a flag to create these automatically; we need
            ## a pre-validation run to list what would be created.
            my $allergen = $db->resultset('ProductAllergenType')->find(
                { 'description' => $allername } )
            or die(qq{Error: Unable to find Allergen in the database:\n$allername\n});
            
            $db->resultset('ProductAllergen')->update_or_create({
                product_id               => $product->id(),
                product_allergen_type_id => $allergen->id(),
                present                  => $present,
            });
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

    my $db = $self->database;

    eval {
        $db->txn_do( sub { $self->_load_table_data($fh); } );
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

package main;

sub parse_args {

    my ( $input, $want_help );

    GetOptions(
	"i|input=s"  => \$input,
        "h|help"     => \$want_help,
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

    return( $input, $config );
}

my ( $input, $config ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $loader = AllergenLoader->new( database => $schema );

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

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
