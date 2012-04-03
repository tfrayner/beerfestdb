#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2012 Tim F. Rayner
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

package BeerFestDB::Web::Controller::User;
use Moose;
use namespace::autoclean;

use Digest;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        user_id            => 'user_id',
        username           => 'username',
        password           => 'password',
        name               => 'name',
        email              => 'email',
    });
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->delete_from_resultset( $c, $rs );
}

sub build_database_object : Private {

    my ( $self, $rec, @other ) = @_;

    # FIXME this overridden method needs to hash any $rec->password
    # field before passing it back to the superclass method. Note that
    # we'd also like to salt these hashes FIXME.
    
#    if ( my $pw = $rec->{'password'} ) {
#        my $ctx = Digest->new('SHA-1');
#        $ctx->add( $pw );
#        $rec->{'password'} = ctx->hexdigest();
#    }

    $self->next::method( $rec, @other );
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $pk = 'user_id';
    
    my $id = $c->request->param( $pk );

    if ( $id != eval{ $c->user->user_id } && ! $c->check_any_user_role('admin') ) {
        $c->stash->{error} = 'You are not authorised to access these data.';
        $c->detach( '/access_denied' );
    }

    my $rs = $c->model('DB::User');

    $self->form_json_and_detach( $c, $rs, $pk );
}

# FIXME this is just a vague outline at the moment.
sub modify : Local {

    my ( $self, $c ) = @_;

    # Quick check for authorisation; we may need to put in other
    # checks for content FIXME.
    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    foreach my $rec ( @{ $data } ) {
        if ( $rec->{'user_id'} != eval{ $c->user->user_id } ) {
            $c->stash->{error} = 'You are not authorised to edit these data.';
            $c->detach( '/access_denied' );
        }
    }

    # Pass-through to submit action for the moment FIXME?
    $self->submit( $c );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
