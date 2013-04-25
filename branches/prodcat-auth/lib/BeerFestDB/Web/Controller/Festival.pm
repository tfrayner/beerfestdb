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

package BeerFestDB::Web::Controller::Festival;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Festival - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        festival_id     => 'festival_id',
        year            => 'year',
        name            => 'name',
        description     => 'description',
        fst_start_date  => 'fst_start_date',
        fst_end_date    => 'fst_end_date',
    });
}

=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Just redirect to the main festival grid for now.
    $c->response->redirect($c->uri_for('grid'));
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Festival');

    $self->form_json_and_detach( $c, $rs, 'festival_id' );
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::Festival')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Festival not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object}     = $object;

    return;
}

=head2 status

=cut

sub status : Local {

    my ( $self, $c, $id ) = @_;

    $id ||= $c->request->param( 'festival_id' );

    my $festival = $c->model('DB::Festival')->find($id);

    unless ( $festival ) {
        $c->stash->{ 'error' }   = "Error: Festival not found.";
        $c->stash->{ 'success' } = JSON::Any->false();
        $c->detach( $c->view( 'JSON' ) );
    }
    
    # Here we're going to be a bit cheeky and hard-code a
    # ProductCategory (beer) and ContainerSize
    # (kilderkin). Alternatively we could (and should) create new
    # default config items FIXME.
    my $beercat = $c->model('DB::ProductCategory')->find({ description => 'beer' });
    unless ( $beercat ) {
        $c->stash->{ 'error' }   = "Error: beer ProductCategory not found.";
        $c->stash->{ 'success' } = JSON::Any->false();
        $c->detach( $c->view( 'JSON' ) );
    }
    my $kilsize = $c->model('DB::ContainerSize')->find({ description => 'kilderkin' });
    unless ( $kilsize ) {
        $c->stash->{ 'error' }    = "Error: kilderkin ContainerSize not found.";
        $c->stash->{ 'success' }  = JSON::Any->false();
        $c->detach( $c->view( 'JSON' ) );
    }

    # kils_ordered
    my $orders = $festival->search_related('order_batches')
                          ->search_related('product_orders',
                                           { 'product_id.product_category_id' => $beercat->id(),
                                             'is_final'                       => 1 },
                                           { join => 'product_id' } );
    my $order_tot = 0;
    my $sor_order_tot = 0;
    while ( my $order = $orders->next() ) {
        my $vol = $order->container_size_id()->container_volume() * $order->cask_count();
        $order_tot += $vol;
        if ( $order->is_sale_or_return() ) {
            $sor_order_tot += $vol;
        }
    }

    # kils_remaining and num_beers_available
    my $casks  = $festival->search_related('cask_managements')
                          ->search_related('casks',
        { 'product_id.product_category_id' => $beercat->id() },
        { join => {
            gyle_id => { festival_product_id => 'product_id' }
        }
      }
    );
    
    my $remaining_tot = 0;
    my %product_available;

    CASK:
    while ( my $cask = $casks->next() ) {
        next CASK if $cask->is_condemned();
        my @meas = $cask->search_related(
            'cask_measurements',
            undef,
            {
                join     => 'measurement_batch_id',
                order_by => { -desc => 'measurement_batch_id.measurement_time' },
            }
        );
        if ( my $latest = $meas[0] ) {
            $remaining_tot += $latest->volume();
            if ( $latest->volume() > 0 ) {
                $product_available{ $cask->gyle_id->get_column('festival_product_id') }++;
            }
        }
        else {
            $remaining_tot += $cask->cask_management()
                                   ->container_size_id()
                                   ->container_volume();
            $product_available{ $cask->gyle_id->get_column('festival_product_id') }++;
        }
    }
    my $kilvol = $kilsize->container_volume();
    my $ko = $order_tot     / $kilvol;
    my $ks = $sor_order_tot / $kilvol;
    my $kr = $remaining_tot / $kilvol;
    my $pc = $ko != 0 ? sprintf("%.1f%%", ($kr/$ko) * 100) : q{};
    my %obj_hash = (
        kils_ordered   => sprintf('%.1f', $ko),
        kils_sale_or_return => sprintf('%.1f', $ks),
        kils_remaining => sprintf('%.1f %s', $kr, $pc),
        num_beers_available => scalar( grep { defined $_ } values %product_available ),
    );

    $c->stash->{ 'data' }    = \%obj_hash;
    $c->stash->{ 'success' } = JSON::Any->true();

    $c->detach( $c->view( 'JSON' ) );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
