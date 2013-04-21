#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2013 Tim F. Rayner
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

package BeerFestDB::CaskPreloader;
use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw(looks_like_number);
use List::Util qw(max);
use BeerFestDB::Web;
use BeerFestDB::ORM;

=head1 NAME

BeerFestDB::CaskPreloader - Populating CaskManagement.

=head1 DESCRIPTION

This is a Role class used to synchronise information between
product_order and cask_management tables.

=head1 METHODS

=head2 preload_product_order

=cut

sub preload_product_order {

    my ( $self, $order ) = @_;

    my $db = $order->result_source->schema();

    # Preload each product order in a transaction.
    eval {
        $db->txn_do(
            sub {
                $self->_txn_preload_product_order( $order, $db );
            }
        );
    };
    if ( $@ ) {
        die(qq{Errors encountered during cask preload:\n\n$@});
    }

    return;
}

sub _txn_preload_product_order {

    my ( $self, $order, $db ) = @_;

    my $festival = $order->order_batch_id->festival_id;
    my $fest_id  = $festival->get_column('festival_id');

    # We need to go around the houses a bit here so that all the casks
    # for a given product at the festival are counted.
    my $product_max = max(

        # Cask management entries associated with product order.
        $order->search_related('product_id')
              ->search_related('product_orders')
              ->search_related('order_batch_id', { 'order_batch_id.festival_id' => $fest_id })
              ->search_related('product_orders')
              ->search_related('cask_managements')
              ->get_column('internal_reference')->max() || 0,

        # Cask management entries associated with instantiated casks.
        $festival->search_related('festival_products', { product_id => $order->get_column('product_id') })
                 ->search_related('gyles')
                 ->search_related('casks')
                 ->search_related('cask_management_id')
                 ->get_column('internal_reference')->max() || 0,
    );

    my $previous_festival_max = $db->resultset('CaskManagement')
                                   ->search({ festival_id => $fest_id })
                                   ->get_column('cellar_reference')->max() || 0;


    my %order_details = (
        festival_id        => $fest_id,
        container_size_id  => $order->get_column('container_size_id'),
        currency_id        => $order->get_column('currency_id'),
        is_sale_or_return  => $order->get_column('is_sale_or_return'),
        distributor_company_id => $order->get_column('distributor_company_id'),
    );

    # Deduce price automatically here.
    if ( defined $order->advertised_price && $order->cask_count ) {

        # FIXME rounding errors?
        $order_details{ price } = $order->advertised_price / $order->cask_count;
    }

    my $existing = $order->search_related('cask_managements');
    my $wanted   = $order->is_final ? $order->cask_count() : 0;

    my $existing_count = 0;
    while ( my $caskman = $existing->next() ) {

        # Update pre-existing caskmans with any updated order info
        # (e.g. cask size, is_SOR).
        while ( my ( $col, $value) = each %order_details ) {
            $caskman->set_column($col, $value);
        }
        $caskman->update();
        $existing_count++;
    }
    if ( $existing_count < $wanted ) {

        # Add new caskmans as necessary.
        for ( $existing_count+1 .. $wanted ) {
            warn("Creating new cask...\n");
            $db->resultset("CaskManagement")->create({
                %order_details,
                product_order_id   => $order->get_column("product_order_id"),
                internal_reference => ++$product_max,
                cellar_reference   => ++$previous_festival_max,
            });
        }
    }
    elsif ( $existing_count > $wanted ) {

        # Delete surplus casks where possible (if not possible throw
        # an error). Try to delete the higher-numbered casks first.
        my $existing = $order->search_related('cask_managements',
                                              undef,
                                              { order_by => { -desc => 'internal_reference' } } );

        CASKMAN_DELETE:
        while ( my $caskman = $existing->next() ) {
            warn("Deleting surplus cask...\n");

            # Try to delete caskman. Fully instantiated casks would block this.
            eval {
                $caskman->delete();
            };
            if ( ! $@ && --$existing_count <= $wanted ) {
                last CASKMAN_DELETE;
            }
        }

        # If there's still a problem, throw an exception and break the transaction.
        if ( $existing_count > $wanted ) {
            die(sprintf("Unable to delete surplus cask_management entries for product_order %d\n",
                        $order->product_order_id));
        }
    }

    return;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

no Moose::Role;

1;
