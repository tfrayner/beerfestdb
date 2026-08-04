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

package BeerFestDB::Web::Controller::CaskManagement;
use Moose;
use namespace::autoclean;

use JSON::MaybeXS qw(JSON);
use Data::Dumper;

BEGIN {extends 'BeerFestDB::Web::PriceController'; }

with 'BeerFestDB::Role::DipMunger';

use Storable qw(dclone);

=head1 NAME

BeerFestDB::Web::Controller::CaskManagement - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        cask_management_id   => 'cask_management_id',
        festival_id          => 'festival_id',
        festival_name        => {
            festival_id          => 'name',
        },
        distributor_id       => 'distributor_company_id',
        distributor_name         => {
            distributor_company_id => 'name',
        },
        container_size_id    => 'container_size_id',
        bar_id               => 'bar_id',
        stillage_location_id => 'stillage_location_id',
        currency_id          => 'currency_id',
        price                => 'price',
        stillage_bay         => 'stillage_bay',
        bay_position_id      => 'bay_position_id',
        stillage_x           => 'stillage_x_location',
        stillage_y           => 'stillage_y_location',
        stillage_z           => 'stillage_z_location',
        int_reference        => 'internal_reference',
        festival_ref         => 'cellar_reference',
        is_sale_or_return    => 'is_sale_or_return',
        cask_graveyard       => 'cask_graveyard',
        company_id           => undef,  # See viewhash_from_model for how these are derived
        company_name         => undef,
        product_id           => undef,
        product_name         => undef,
        order_batch_id       => undef,
        order_batch_name     => undef,
    });

    $self->price_field('price');
    $self->currency_id_field('currency_id');
}

sub viewhash_from_model : Private {

    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    # We navigate to the company and product via the cask_id if it exists, otherwise we use the product_order_id.
    if ( $dbrow->result_source->has_column('casks') && $dbrow->casks->count ) {
        my $map = {
            company_name => sub { $_[0]->casks->first->gyle_id->festival_product_id->product_id->company_id->name },
            company_id   => sub { $_[0]->casks->first->gyle_id->festival_product_id->product_id->company_id->id },
            product_name => sub { $_[0]->casks->first->gyle_id->festival_product_id->product_id->name },
            product_id   => sub { $_[0]->casks->first->gyle_id->festival_product_id->product_id->id },
            order_batch_name => sub { undef },
            order_batch_id   => sub { undef },
        };
        if ( exists $map->{$view_key} ) {
            return $map->{$view_key}->($dbrow);
        }
    }
    elsif ( $dbrow->result_source->has_column('product_order_id') && $dbrow->product_order_id ) {
        my $map = {
            company_name => sub { $_[0]->product_order_id->product_id->company_id->name },
            company_id   => sub { $_[0]->product_order_id->product_id->company_id->id },
            product_name => sub { $_[0]->product_order_id->product_id->name },
            product_id   => sub { $_[0]->product_order_id->product_id->id },
            order_batch_name => sub { $_[0]->product_order_id->order_batch_id->description },
            order_batch_id   => sub { $_[0]->product_order_id->order_batch_id->id },
        };
        if ( exists $map->{$view_key} ) {
            return $map->{$view_key}->($dbrow);
        }
    }

    return $self->next::method( $view_key, $dbrow, $lookup );
}

sub build_database_object : Private {

    my ( $self, $rec, $c, @other ) = @_;

    foreach my $key ( keys %$rec ) {
        if ( ! defined $self->model_view_map()->{$key} ) {
            delete $rec->{$key};
        }
    }

    $self->next::method( $rec, $c, @other );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::CaskManagement')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: CaskManagement not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    $c->stash->{object} = $object;

    # Need the category for navigation back to stillage planning grid.
    if ( $object->casks->count ) {
        $c->stash->{category_id} = $object->casks->first->gyle_id->festival_product_id
                                          ->product_id->get_column('product_category_id');
    } else {
        $c->stash->{category_id} = $object->product_order_id
                                          ->product_id->get_column('product_category_id');
    }

    return;
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::CaskManagement');

    $self->form_json_and_detach( $c, $rs, 'cask_management_id' );
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$festival_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        # Collect matching cask_management_id values via two independent subqueries —
        # one traversing the casks->gyle->festival_product->product path and one
        # traversing the product_order->product path — then return CaskManagement
        # objects for the union.  Using separate subqueries avoids a single query
        # with conflicting JOIN requirements and preserves LEFT-JOIN semantics for
        # each path independently.
        my $via_casks = $festival->search_related(
            'cask_managements',
            { 'product_id.product_category_id' => $category_id },
            {
                join    => { casks => { gyle_id => { festival_product_id => 'product_id' } } },
                columns => ['me.cask_management_id'],
            }
        )->as_query;

        my $via_orders = $festival->search_related(
            'cask_managements',
            { 'product_id.product_category_id' => $category_id },
            {
                join    => { product_order_id => 'product_id' },
                columns => ['me.cask_management_id'],
            }
        )->as_query;

        $rs = $c->model('DB::CaskManagement')->search(
            [
                { 'me.cask_management_id' => { '-in' => $via_casks  } },
                { 'me.cask_management_id' => { '-in' => $via_orders } },
            ],
            {
                prefetch => [
                    { casks => { gyle_id => { festival_product_id => { product_id => 'company_id' } } } },
                    { product_order_id => [
                        { product_id => 'company_id' },
                        'order_batch_id',
                    ] },
                ],
            }
        );
    }
    else {
        die('Error: festival_id not defined.');
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $festival = $c->model('DB::Festival')->find($festival_id);
    unless ( $festival ) {
        $c->flash->{error} = qq{Festival ID "$festival_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{festival} = $festival;

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = qq{Product category ID "$category_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;

    $self->get_default_currency( $c );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::CaskManagement' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::CaskManagement' );

    $self->delete_from_resultset( $c, $rs );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
