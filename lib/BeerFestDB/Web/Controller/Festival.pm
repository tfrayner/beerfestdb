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
use JSON::MaybeXS;

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
        $c->stash->{ 'success' } = JSON->false();
        $c->forward( 'View::JSON' );
    }

    my $default_meas_unit = $c->model('DB::ContainerMeasure')->find({
        description => $c->config->{'default_measurement_unit'},
    }) or die("Unable to retrieve default measurement unit; check config settings.");

    # Here we're going to be a bit cheeky and hard-code a
    # ProductCategory (beer) and ContainerSize
    # (kilderkin). Alternatively we could (and should) create new
    # default config items FIXME.
    my $beercat = $c->model('DB::ProductCategory')->find({ description => 'beer' });
    unless ( $beercat ) {
        $c->stash->{ 'error' }   = "Error: beer ProductCategory not found.";
        $c->stash->{ 'success' } = JSON->false();
        $c->forward( 'View::JSON' );
    }
    my $kilsize = $c->model('DB::ContainerSize')->find({ description => 'kilderkin' });
    unless ( $kilsize ) {
        $c->stash->{ 'error' }    = "Error: kilderkin ContainerSize not found.";
        $c->stash->{ 'success' }  = JSON->false();
        $c->forward( 'View::JSON' );
    }

    # kils_ordered
    my $orders = $festival
        ->search_related('order_batches')
        ->search_related('product_orders',
                         { 'product_id.product_category_id' => $beercat->id(),
                           'is_final'                       => 1 },
                         { join => 'product_id',
                           prefetch => {
                               container_size_id => 'container_measure_id' } } );
    my $order_tot = 0;
    my $sor_order_tot = 0;
    while ( my $order = $orders->next() ) {
        my $local_cask_size = $order->container_size_id->container_volume();
        my $cask_measure    = $order->container_size_id->container_measure_id();
        my $vol = $order->cask_count()
                * $local_cask_size
                * ( $cask_measure->litre_multiplier() /
                    $default_meas_unit->litre_multiplier() );
        $order_tot += $vol;
        if ( $order->is_sale_or_return() ) {
            $sor_order_tot += $vol;
        }
    }

    # kils_remaining and num_beers_available. Lots of prefetching and
    # joining here to reduce the downstream DB queries and speed the
    # calculation up.
    my $casks  = $festival
        ->search_related('cask_managements')
        ->search_related('casks',
                         {
                             'product_id.product_category_id' => $beercat->id()
                         },
                         {
                             join => {
                                 gyle_id => { festival_product_id => 'product_id' },
                                 cask_measurements => 'measurement_batch_id',
                             },
                             prefetch => [
                                 {
                                     cask_measurements => [
                                         'measurement_batch_id',
                                         'container_measure_id',
                                     ],
                                     cask_management_id => { # Used when querying full casks.
                                         container_size_id => 'container_measure_id',
                                     },
                                 },
                                 'gyle_id',
                             ],
                             order_by =>
                                 [
                                     { # Needed for DBIx::Class prefetch to work safely.
                                         -asc  => 'casks.cask_id',
                                     },
                                     { # Used later to select the latest dip for each cask.
                                         -desc => 'measurement_batch_id.measurement_time',
                                     }
                                 ],
                         }
                     );

    my $remaining_tot = 0;
    my %product_available;

    CASK:
    while ( my $cask = $casks->next() ) {
        next CASK if $cask->is_condemned();

        my $meas = $cask->search_related('cask_measurements');
        if ( my $latest = $meas->first() ) {
            my $cask_measure = $latest->container_measure_id();
            my $vol = $latest->volume()
                    * ( $cask_measure->litre_multiplier() /
                        $default_meas_unit->litre_multiplier() );
            $remaining_tot += $vol;
            if ( $latest->volume() > 0 ) {
                $product_available{ $cask->gyle_id->get_column('festival_product_id') }++;
            }
        }
        else {
            my $cask_size    = $cask->cask_management_id->container_size_id();
            my $cask_measure = $cask_size->container_measure_id();
            my $vol = $cask_size->container_volume()
                    * ( $cask_measure->litre_multiplier() /
                        $default_meas_unit->litre_multiplier() );
            $remaining_tot += $vol;
            $product_available{ $cask->gyle_id->get_column('festival_product_id') }++;
        }
    }

    # This is the reporting volume unit (kil) in
    # default_measurement_units (gallons).
    my $kilvol = $kilsize->container_volume()
               * ( $kilsize->container_measure_id()->litre_multiplier() /
                   $default_meas_unit->litre_multiplier() );
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
    $c->stash->{ 'success' } = JSON->true();

    $c->forward( 'View::JSON' );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
