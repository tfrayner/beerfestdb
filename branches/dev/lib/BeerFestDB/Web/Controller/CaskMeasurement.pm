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

package BeerFestDB::Web::Controller::CaskMeasurement;
use Moose;
use namespace::autoclean;

use JSON::Any;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::CaskMeasurement - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        cask_measurement_id    => 'cask_measurement_id',
        cask_id                => 'cask_id',
        measurement_batch_id   => 'measurement_batch_id',
        volume                 => 'volume',
        container_measure_id   => 'container_measure_id',
        comment                => 'comment',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::CaskMeasurement in CaskMeasurement.');
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $batch_id, $stillage_id ) = @_;

    # This listing actually revolves around casks rather than
    # cask_measurements. Perhaps it's in the wrong controller? FIXME?
    unless ( defined $stillage_id && defined $batch_id ) {
        die("Error: stillage_location_id or measurement_batch_id not defined.");
    }
    
    my $stillage = $c->model( 'DB::StillageLocation' )
                     ->find({stillage_location_id => $stillage_id});
    unless ( $stillage ) {
        $c->stash->{error} = 'Stillage location not found.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }
    my $rs = $stillage->search_related('casks');

    my $batch = $c->model( 'DB::MeasurementBatch' )
                  ->find({measurement_batch_id => $batch_id});
    unless ( $batch ) {
        $c->stash->{error} = 'Measurement batch not found.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    # We handle this mapping here rather than in the generic
    # superclass since it's a little different from normal.

    # Iterate over $rs and add in the current batch info (if
    # available) and the previous data.
    my @casks;
    while ( my $cask = $rs->next() ) {

        # We actually want to use the comment field attached to cask,
        # rather than the one attached to cask_measurement.
        my %cask_info = map { $_ => $cask->get_column($_) }
            qw( cask_id internal_reference cellar_reference
                is_vented is_tapped is_ready is_condemned );
        $cask_info{ measurement_batch_id } = $batch_id;

        # We distinguish cask comment since there's also a cask_measurement comment.
        $cask_info{ cask_comment } = $cask->get_column('comment');

        # For information only. Will not be edited in the View.
        $cask_info{ container_measure }
            = $cask->container_size_id()->container_measure_id()->description();
        $cask_info{ brewer }
            = $cask->gyle_id()->company_id()->name();
        $cask_info{ product }
            = $cask->gyle_id()->festival_product_id()->product_id()->name();

        # Add in the volume and unit for this batch.
        my @meas = $cask->search_related('cask_measurements',
                                         { measurement_batch_id => $batch_id });
        my $current = $meas[0];
        $cask_info{ volume }
            = defined $current ? $current->volume() : undef;
        $cask_info{ cask_measurement_id }
            = defined $current ? $current->cask_measurement_id() : undef;

        # Add in the previous volume to date.
        my @older = $cask->search_related(
            'cask_measurements',
            { 'measurement_batch_id.measurement_time' => { '<' => $batch->measurement_time() } },
            {
                join     => 'measurement_batch_id',
                order_by => { -desc => 'measurement_batch_id.measurement_time' },
            },
        );
        my $previous = $older[0];
        $cask_info{ previous_volume } = defined $previous
                                      ? $previous->volume()
                                      : $cask->container_size_id->container_volume();
        
        push @casks, \%cask_info;
    }

    $c->stash->{ 'success' } = JSON::Any->true();
    $c->stash->{ 'objects' } = \@casks;
    $c->detach( $c->view( 'JSON' ) );
}

=head2 list_by_cask

=cut

sub list_by_cask : Local {

    my ( $self, $c, $cask_id ) = @_;

    my $rs;
    if ( defined $cask_id ) {
        $rs = $c->model( 'DB::CaskMeasurement' )->search_rs( { cask_id => $cask_id } );
    }
    else {
        $rs = $c->model( 'DB::CaskMeasurement' );  # FIXME is this actually needed?
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;
    
    my $rs = $c->model( 'DB::CaskMeasurement' );

    # This is special-cased since it handles CaskMeasurement and Cask
    # information simultaneously.

    # Note that the previous dip measurement is assumed not to be
    # returned from the view component.
    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    eval {
        $rs->result_source()->schema()->txn_do(
            sub { $self->_save_records( $c, $rs, $data ) }
        );
    };
    if ( $@ ) {
        $self->detach_with_txn_failure( $c, $@ );
    }
    
    $c->stash->{success} = JSON::Any->true();

    $c->detach( $c->view( 'JSON' ) );
}

sub _save_records : Private {

    my ( $self, $c, $rs, $data ) = @_;

    RECORD:
    foreach my $rec ( @{ $data } ) {
        my $cask  = $c->model( 'DB::Cask' )->find( { cask_id => $rec->{cask_id} } );
        unless ( $cask ) {
            die("Cask with ID=$rec->{cask_id} not found");
        }

        # Cask-level editing at the point of dip entry for convenience.
        foreach my $field ( qw(cask_comment) ) {

            my ( $cfield ) = ( $field =~ m/\A cask_(.*)/xms );

            # Empty string is allowed.
            $cask->set_column($cfield, delete $rec->{$field}) if defined $rec->{$field};
        }
        foreach my $field ( qw(is_vented is_tapped is_ready is_condemned) ) {

            # No empty strings allowed for tinyints.
            $cask->set_column($field, delete $rec->{$field})
                if ( defined $rec->{$field} && $rec->{$field} ne q{} );
        }
        $cask->update();

        # We are assuming all measurement units are the same as the
        # cask size unit (i.e. gallons, for the most part).

	# Allow the UI to pass in an empty string to indicate we
	# should delete the pre-existing dip.
	if ( defined ( $rec->{volume} ) && $rec->{volume} eq q{} ) {
	    my %attr  = map { $_ => $rec->{$_} } qw( cask_id measurement_batch_id );
	    if ( my $dbobj = $rs->find(\%attr) ) {
		$dbobj->delete();
	    }
	}
	else {
	    $rec->{container_measure_id}
	        = $cask->container_size_id()
		       ->get_column('container_measure_id');
	    $self->build_database_object( $rec, $c, $rs );
	}
    }

    return;
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::CaskMeasurement' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $batch_id, $stillage_id ) = @_;

    if ( defined $batch_id ) {
        my $batch = $c->model('DB::MeasurementBatch')->find($batch_id);
        unless ( $batch ) {
            $c->flash->{error} = "Error: MeasurementBatch not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{batch}    = $batch;
        $c->stash->{festival} = $batch->festival_id();
    }
    else {
        $c->flash->{error} = "Error: measurement_batch_id not defined.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    if ( defined $stillage_id ) {
        my $stillage = $c->model('DB::StillageLocation')->find($stillage_id);
        unless ( $stillage ) {
            $c->flash->{error} = "Error: StillageLocation not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{stillage} = $stillage;
    }
    else {
        $c->flash->{error} = "Error: stillage_location_id not defined.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
