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

package BeerFestDB::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

BeerFestDB::Web::Controller::Root - Root Controller for BeerFestDB::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private { 
    my ( $self, $c ) = @_; 
    $c->response->status('404'); 
    $c->stash->{template} = 'not_found.tt2'; 
} 

=head2 access_denied

The default action called if the user attempts to navigate somewhere
they're not permitted. This is called by the Authorization::ACL plugin.

=cut

sub access_denied : Private {
    my ( $self, $c, $action ) = @_;

    $c->res->status('403');

    if (!$c->user_exists) {

	# Handle cases where we're not running at server root
	# (e.g. behind a reverse proxy).
	my $base = $c->config->{ 'base_path' };
	my $uri  = $c->req->uri;
	if ( defined $base ) {
	    $uri->path($base . $uri->path);
	}

        # Set up the post-login destination URI.
        $c->flash->{url_success_target} = '' . $uri;

        # Redirect the user to the login page.
        $c->res->redirect( $c->uri_for('/login') );
    }
    else {
        $c->stash->{template} = 'denied.tt2';
    }
}

=head2 index

=cut

sub index : Private {};

=head2 login

The primary login action, tied into the users/roles table system in
the underlying database.

=cut

sub login : Global {

    my ( $self, $c ) = @_;

    # Not sure why this works; possibly it's circumventing the reset
    # of user session, or maybe some Authorization::ACL oddness?
    # N.B. currently this forgets the target if the user hits reload
    # on the web page. FIXME?
    $c->stash->{'url_success_target'}
        = $c->flash->{'url_success_target'} || '' . $c->uri_for('/');

    my $j = JSON::Any->new;
    my $json_req = $c->request->param( 'data' );

    $c->res->status('403');

    return unless $json_req;

    my $data = $j->jsonToObj( $json_req );

    if ( $c->authenticate({ username => $data->{ 'username' },
                            password => $data->{ 'password' }, }) ) {

        # ExtJS form redirects to url_success_target URI.
	$c->res->status('200');
        $c->stash->{ 'success' } = JSON::Any->true();
        $c->detach( $c->view( 'JSON' ) );
    }
    else {
        $c->res->status('401');
        $c->stash->{ 'message' } = 'Login failed.';
        $c->stash->{ 'success' } = JSON::Any->false();
        $c->detach( $c->view( 'JSON' ) );
    }

    return;
}

=head2 logout

Standard logout action.

=cut

sub logout : Global {

    my ( $self, $c ) = @_;

    # Whatever happens we want to log out.
    $c->logout;

    $c->flash->{ 'message' } = 'Successfully logged out.';
    $c->stash->{ 'success' } = JSON::Any->true();
    $c->res->redirect( $c->uri_for('/') );
}

sub auto : Private {

    my ($self, $c) = @_;

    # Prepend all uri_for paths so that this works under a reverse proxy.
    my $base = $c->config->{ 'base_path' };
    if ( defined $base ) {
	my $uri = $c->req->base;
	$uri->path($base);
	$c->req->base($uri);
	$c->stash->{'base_path'} = $base;
    }
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
