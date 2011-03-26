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

package BeerFestDB::Web::Controller::Contact;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Contact - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        contact_id      => 'contact_id',
        company_id      => 'company_id',
        contact_type_id => 'contact_type_id',
        first_name      => 'first_name',
        last_name       => 'last_name',
        street_address  => 'street_address',
        postcode        => 'postcode',
        email           => 'email',
        country_id      => 'country_id',
        comment         => 'comment',
    });
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $company_id ) = @_;

    my $company = $c->model('DB::Company')->find($company_id);
    unless ( $company ) {
        $c->flash->{error} = qq{Company ID "$company_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{company} = $company;
}

=head2 list_by_company

=cut

sub list_by_company : Local {

    my ( $self, $c, $company_id ) = @_;

    my $rs = $c->model( 'DB::Contact' )->search({ company_id => $company_id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Contact');

    $self->form_json_and_detach( $c, $rs, 'contact_id' );
}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::Contact')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Contact not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object}     = $object;

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Contact' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Contact' );

    $self->delete_from_resultset( $c, $rs );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
