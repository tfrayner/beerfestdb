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

package BeerFestDB::Web::Controller::Cask;
use Moose;
use namespace::autoclean;

use JSON::Any;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

with 'BeerFestDB::DipMunger';

=head1 NAME

BeerFestDB::Web::Controller::Cask - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        cask_id           => 'cask_id',
        festival_id       => 'festival_id',
        distributor_id    => 'distributor_company_id',
        order_batch_id    => 'order_batch_id',
        container_size_id => 'container_size_id',
        bar_id            => 'bar_id',
        stillage_location_id => 'stillage_location_id',
        currency_id       => 'currency_id',
        price             => 'price',
        gyle_id           => 'gyle_id',
        product_id        => {
            gyle_id  => {
                festival_product_id => 'product_id',
            },            
        },
        company_id        => {
            gyle_id  => 'company_id',
        },
        stillage_bay      => 'stillage_bay',
        stillage_x        => 'stillage_x_location',
        stillage_y        => 'stillage_y_location',
        stillage_z        => 'stillage_z_location',
        comment           => 'comment',
        ext_reference     => 'external_reference',
        int_reference     => 'internal_reference',
        festival_ref      => 'cellar_reference',
        is_vented         => 'is_vented',
        is_tapped         => 'is_tapped',
        is_ready          => 'is_ready',
        is_condemned      => 'is_condemned',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Cask in Cask.');
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
        $rs = $festival->search_related(
            'casks',
            { 'product_id.product_category_id' => $category_id },
            {
                join     => { gyle_id =>
                                  { festival_product_id =>
                                        { product_id => 'product_category_id' } } },
            });
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
}

=head2 list_by_stillage

=cut

sub list_by_stillage : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::Cask' )->search({ stillage_location_id => $id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_festival_product

=cut

sub list_by_festival_product : Local {

    my ( $self, $c, $id ) = @_;

    my $fp = $c->model( 'DB::FestivalProduct' )
               ->find({ festival_product_id => $id });

    my $rs = $c->model( 'DB::Cask' )
               ->search({
                   'me.festival_id'              => $fp->get_column('festival_id'),
                   'gyle_id.festival_product_id' => $fp->get_column('festival_product_id'),
               }, { join => { gyle_id => 'festival_product_id' } });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_dips

=cut

sub list_dips : Local {

    my ( $self, $c, $cask_id ) = @_;

    my $cask = $c->model('DB::Cask')->find({ cask_id => $cask_id });

    unless ( $cask ) {
        $c->stash->{error} = 'Cask not found.';
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();
    }

    my $dips;
    eval {
        $dips = $self->munge_dips( $cask );
    };
    if ( $@ ) {
        $self->detach_with_txn_failure( $c, $@ );
    }

    $c->stash->{ 'objects' } = $dips;
    $c->stash->{ 'success' } = JSON::Any->true();

    $c->detach( $c->view( 'JSON' ) );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 delete_from_stillage

=cut

sub delete_from_stillage : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    eval {
        $rs->result_source()->schema()->txn_do(
            sub {
                foreach my $id ( @{ $data } ) {
                    my $rec = $rs->find($id);
                    eval {
                        $rec->set_column('stillage_location_id', undef) if $rec;
                        $rec->update();
                    };
                    if ($@) {
                        die("Unable to delete Cask with ID=$id from stillage\n");
                    }
                }
            }
        );
    };
    if ( $@ ) {
        $self->detach_with_txn_failure( $c, $rs, $@ );
    }

    $c->detach( $c->view( 'JSON' ) );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
