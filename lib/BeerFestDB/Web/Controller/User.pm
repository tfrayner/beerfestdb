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

use Crypt::SaltedHash;
use List::Util qw(first);
use JSON::MaybeXS;

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
        roles              => undef,
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::User')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: User not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
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

    my ( $self, $rec, $c, @other ) = @_;

    # This overridden method needs to hash any $rec->password
    # field before passing it back to the superclass method.
    my $pw = $rec->{'password'};
    if ( defined $pw ) {
        if ( $pw eq q{} ) {
            delete $rec->{'password'}; # no empty passwords
        }
        else {
            my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
            $csh->add($pw);
            $rec->{'password'} = $csh->generate();
        }
    }

    # Our regular build_database_object method doesn't handle many-to-many.
    my $roles = delete $rec->{'roles'};

    my $obj = $self->next::method( $rec, $c, @other );

    if ( defined $roles && defined $obj ) {
        my $rs = $c->model( 'DB::UserRole' );
        my @r = split /,/, $roles;
        foreach my $existing ($obj->user_roles) {

            # Delete unwanted existing roles.
            if ( ! first { $existing->get_column('role_id') == $_ } @r ) {
                $existing->delete;
            }
        }
        foreach my $role_id (@r) {

            # Check that all the wanted roles are set.
            $rs->find_or_create({ user_id => $obj->user_id(), role_id => $role_id });
        }
    }

    return $obj;
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

# FIXME this is just a vague outline at the moment. It's intended as a
# means for a given user to be able to edit their own account
# (e.g. change password).
sub modify : Local {

    my ( $self, $c ) = @_;

    # Quick check for authorisation; we may need to put in other
    # checks for content FIXME.
    my $data = $self->decode_json_changes($c);

    foreach my $rec ( @{ $data } ) {
        if ( $rec->{'user_id'} != eval{ $c->user->user_id } ) {
            $c->stash->{error} = 'You are not authorised to edit these data.';
            $c->detach( '/access_denied' );
        }
    }

    # Pass-through to submit action for the moment FIXME?
    $self->submit( $c );
}

sub generate_object_viewhash : Private {

    my ( $self, $obj ) = @_;

    # Don't publish the SHA-1 password hash; just leave it blank.
    my $obj_info = $self->next::method( $obj );
    delete $obj_info->{'password'};
    return $obj_info;
}

sub viewhash_from_model : Private {

    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    my $rc;
    if ( $view_key eq 'roles' ) {
        $rc = join(',', map { $_->get_column('role_id') } $dbrow->roles);
    }
    else {
        $rc = $self->next::method( $view_key, $dbrow, $lookup );
    }

    return $rc;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
