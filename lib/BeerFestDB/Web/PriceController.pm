#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2026 Tim F. Rayner
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

package BeerFestDB::Web::PriceController;
use Moose;
use Scalar::Util qw/reftype/;
use namespace::autoclean;
use Carp;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

# Subclasses must indicate which field contains the price and currency by setting
# the price_field and currency_id_field attributes. Otherwise they're assumed to be 'price' and 'currency_id' respectively.
has 'price_field' => ( is       => 'rw',
                       isa      => 'Str',
                       required => 1,
                       default  => 'price' );

has 'currency_id_field' => ( is       => 'rw',
                             isa      => 'Str',
                             required => 1,
                             default  => 'currency_id' );

with 'BeerFestDB::Role::PriceMunger';

=head1 NAME

BeerFestDB::Web::PriceController - BeerFestDB Controller with price handling.

=head1 DESCRIPTION

Catalyst Controller abstract price-handling class.

=head1 METHODS

=head2 generate_object_viewhash

Overrides the default generate_object_viewhash method to format the price field for display in the UI.

=cut

sub generate_object_viewhash {

    my ( $self, $obj, $c ) = @_;

    my $hash = $self->next::method($obj, $c);

    # Format the price for display in the UI.
    my $field = $self->price_field();
    if ( exists $hash->{$field} ) {
        my $currency = $self->_fetch_currency($hash, $c);
        $hash->{$field} = $self->format_price(
            $hash->{$field}, $currency
        );
    }

    return $hash;
}

=head2 decode_json_changes

Overrides the default decode_json_changes method to parse the price field from the JSON data.

=cut

sub decode_json_changes : Private {

    my ( $self, $c ) = @_;

    my $data = $self->next::method($c);

    my $field = $self->price_field();
    foreach my $rec ( @{ $data } ) {
        # Note that $rec is just an integer if we're deleting records
        my $type = reftype($rec) // 'scalar';
        if ( $type eq 'HASH' && exists $rec->{$field} ) {
            my $currency = $self->_fetch_currency($rec, $c);
            $rec->{$field} = $self->parse_price(
                $rec->{$field}, $currency
            );
        }
    }

    return $data;
}

=head2 get_default_currency

Adds the default currency to the stash for display in the UI.

=cut

sub get_default_currency : Private {

    my ( $self, $c ) = @_;

    my $def = $self->_fetch_default_currency($c);

    $c->stash->{ 'default_currency' } = $def->currency_id();

    return;
}

sub _fetch_currency {

    my ( $self, $hash, $c ) = @_;

    my $currency;

    my $curr_id = $self->currency_id_field();
    if (exists $hash->{$curr_id}) {
        $currency = $c->model('DB::Currency')->find($hash->{$curr_id});
    } else {
        $currency = $self->_fetch_default_currency($c);
    }

    return $currency;
}

sub _fetch_default_currency {

    my ( $self, $c ) = @_;

    my $defaults = $c->model('DB::SystemDefaults')->find(1);

    # Just use the configured currency and sale volumes for now.
    my $currency;
    $currency = $defaults->currency() if $defaults;
    if ( ! $currency ) {
        carp(qq{Warning: unable to find default currency in system_defaults table; falling back to configured default currency.\n});
        $currency = $c->model('DB::Currency')->find({
            currency_code => $c->config()->{ default_currency }
        }) or die(qq{Error: unable to find default currency in database.\n});
    }

    $self->default_currency($currency);

    return $currency;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
