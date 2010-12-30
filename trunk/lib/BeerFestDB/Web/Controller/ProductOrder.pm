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

package BeerFestDB::Web::Controller::ProductOrder;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductOrder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_order_id  => 'product_order_id',
        company_id        => {
            product_id  => 'company_id',
        },
        product_id        => 'product_id',
        order_batch_id    => 'order_batch_id',
        festival_id       => {
            order_batch_id => 'festival_id',
        },
        distributor_id    => 'distributor_company_id',
        container_size_id => 'container_size_id',
        cask_count        => 'cask_count',
        currency_id       => 'currency_id',
        price             => 'advertised_price',
        is_final          => 'is_final',
        comment           => 'comment',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $order_batch_id, $category_id ) = @_;

    # This method is intended to generally work with a defined
    # order_batch_id; however, since it was based on the equivalent
    # action in Product, it can in principle support a listing of all
    # orders ever.

    my ( $cond, $attrs );
    if ( defined $category_id ) {
        $cond  = { 'product_id.product_category_id' => $category_id };
        $attrs = { join => { product_id => 'product_category_id' } };
    }

    my ( $rs, $order_batch );
    if ( defined $order_batch_id ) {
        $order_batch = $c->model( 'DB::OrderBatch' )->find({
            order_batch_id => $order_batch_id});
        unless ( $order_batch ) {
            $c->stash->{error} = 'OrderBatch not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $order_batch->search_related('product_orders', $cond, $attrs)
    }
    else {
        $rs = $c->model( 'DB::ProductOrder' )->search_rs( $cond, $attrs );
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $order_batch_id, $category_id ) = @_;

    if ( defined $order_batch_id ) {
        my $order_batch = $c->model('DB::OrderBatch')->find($order_batch_id);
        unless ( $order_batch ) {
            $c->flash->{error} = "Error: OrderBatch not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{order_batch} = $order_batch;
        $c->stash->{festival}    = $order_batch->festival_id();
    }

    # It's not clear yet whether splitting orders by category is
    # actually desirable.
    if ( defined $category_id ) {
        my $category = $c->model('DB::ProductCategory')->find($category_id);
        unless ( $category ) {
            $c->flash->{error} = "Error: Product category not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{category} = $category;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
