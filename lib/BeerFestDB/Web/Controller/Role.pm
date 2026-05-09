#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2026 by Tim F. Rayner
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

package BeerFestDB::Web::Controller::Role;
use Moose;
use List::Util qw(first);
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::GenericGrid'; }

=head1 NAME

BeerFestDB::Web::Controller::Role - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        role_id            => 'role_id',
        rolename           => 'rolename',
        categories         => undef,
    });

    $self->model_name('DB::Role');
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::Role')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Role not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Role');

    $self->form_json_and_detach( $c, $rs, 'role_id' );
}

sub build_database_object : Private {

    my ( $self, $rec, $c, @other ) = @_;

    # Our regular build_database_object method doesn't handle many-to-many.
    my $categories = delete $rec->{'categories'};

    my $obj = $self->next::method( $rec, $c, @other );

    if ( defined $categories && defined $obj ) {
        my $rs = $c->model( 'DB::CategoryAuth' );
        my @r = split /,/, $categories;
        foreach my $existing ($obj->category_auths) {

            # Delete unwanted existing categories.
            if ( ! first { $existing->get_column('product_category_id') == $_ } @r ) {
                $existing->delete;
            }
        }
        foreach my $category_id (@r) {

            # Check that all the wanted categories are set.
            $rs->find_or_create({ role_id => $obj->role_id(), product_category_id => $category_id });
        }
    }

    return $obj;
}

sub viewhash_from_model : Private {

    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    my $rc;
    if ( $view_key eq 'categories' ) {
        $rc = join(',', map { $_->get_column('product_category_id') } $dbrow->categories);
    }
    else {
        $rc = $self->next::method( $view_key, $dbrow, $lookup );
    }

    return $rc;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
