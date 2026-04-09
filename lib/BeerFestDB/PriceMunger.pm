#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2026 Tim F. Rayner
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

package BeerFestDB::PriceMunger;
use Moose::Role;
use namespace::autoclean;
use Number::Format qw(format_picture);
use BeerFestDB::ORM;

has '_default_currency' => ( is       => 'rw',
                             isa      => 'BeerFestDB::ORM::Currency' );

# This class is a little more complex than ideal, because it is designed to be used from
# both the Dumper class and from the web UI Controller classes, which have different ways
# of accessing the database and configuration. The consuming classes are expected to set
# the default currency prior to accessing the parse_price and format_price methods (ideally
# in their BUILD methods). The price parsing and formatting methods will also attempt to
# fetch the default currency from the database if it hasn't already been set.

sub default_currency {

    # Combined getter/setter for the default currency. The setter functionality is used by
    # the consuming class to set the default currency based on the database query, and the
    # getter functionality is used by the price parsing and formatting methods to access
    # the default currency when needed.

    my ( $self, $currency ) = @_;

    if ( defined $currency ) {
        $self->_default_currency($currency);
    }

    unless ( $self->_default_currency() ) {
        my $currency = $self->_build_currency();
        $self->_default_currency($currency);
    }

    return $self->_default_currency();
}

sub _build_currency {

    # Method of last resort; create a brand new database connection to fetch the
    # default currency if it hasn't already been set by the consuming class.
    require BeerFestDB::Web;

    my ( $self ) = @_;

    my $config = BeerFestDB::Web->config();

    my $schema = BeerFestDB::ORM->connect( @{ $config->{ 'Model::DB' }{ 'connect_info' } } );

    my $currency = $schema->resultset('Currency')->find({
        currency_code => $config->{ default_currency }
    }) or die(qq{Error: unable to find default currency in database.\n});

    return $currency;
}

=head1 NAME

BeerFestDB::PriceMunger - Handling price formatting for BeerFestDB.

=head1 DESCRIPTION

This is a Role class used to parse CSV files and populate the database with the parsed
information. The following documentation is written from the perspective of a user operating
in GBP, but the class should support most currencies (known exceptions: Malagasy ariary
and Mauritanian Ouguiya).

=head1 METHODS

=head2 parse_price

This method is used to parse price values from the CSV file. It currently assumes that the
input value is a simple numeric value representing the price in pounds, and it converts it
to pence by multiplying by 100.

=cut

sub parse_price {

    # Incoming prices will normally be in the default currency, but we support specifying
    # a different currency if needed.

    my ( $self, $value, $currency ) = @_;

    $currency //= $self->default_currency();

    return $value * (10 ** $currency->exponent());
}

=head2 format_price

This method is used to format price values for output. It takes a price value in pence and
formats it according to the default currency's format, which is retrieved from the database.

=cut

sub format_price {

    # Prices being formatted by this method will usually include their attached currency,
    # but if not, the default currency will be used for formatting.

    my ( $self, $price, $currency ) = @_;

    return 'STAFF' unless $price;

    $currency //= $self->default_currency();

    my $format = $currency->currency_format() // die(qq{Error: currency "$currency" does not have a defined format.\n});

    # Find decimal places from format
    my ($before, $after) = split /\./, $format, 2;
    my $decimals = 0;
    if ($after) {
        $decimals = ($after =~ tr/0/0/);
    }

    my $pounds = $price / ( 10 ** $decimals);

    # Format the number
    $format =~ s/0/#/g;  # replace 0 with # for format_picture

    # TODO note that e.g. the original GBP format includes '0.00' in its template 
    # to indicate the minimal formatting desired, but the actual formatting is currently
    # fixed to the number of decimal places in the format, and assumes a leading zero is desirable.
    my $formatted = format_picture($pounds, $format);

    $formatted =~ s/\A \s+//gixms;  # remove leading whitespace from formatted string

    return $formatted;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

no Moose::Role;

1;
