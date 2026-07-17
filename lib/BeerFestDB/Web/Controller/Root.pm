#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2026 Tim F. Rayner
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
use JSON::MaybeXS qw(JSON);

use Data::Dumper;

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

    $c->log->debug("Request access was denied.");

    if (!$c->user_exists) {

	    # Handle cases where we're not running at server root
	    # (e.g. behind a reverse proxy).
        my $base = $c->config->{ 'base_path' };
	    my $uri  = $c->req->uri;
	    if ( defined $base ) {
	        $uri->path($base . $uri->path);
        }

	    $c->log->debug("If login succeeds, will redirect to $uri");

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
    $c->log->debug("login flash: " . Dumper $c->flash);

    if (my $back =  $c->request->params->{'back'}) {

        # OpenIDConnect case
        $c->log->debug("back parameter is set, will redirect to " . $back);
        $c->stash->{url_success_target} = $c->flash->{url_success_target} = '' . $c->uri_for($back);

    } else {

        # Normal case
        $c->stash->{'url_success_target'}
            = $c->flash->{'url_success_target'} || '' . $c->uri_for('/');

    }

    my $j = JSON()->new;
    my $json_req = $c->request->param( 'data' );

    $c->res->status('403');

    return unless $json_req;

    $c->log->debug("login JSON received: $json_req");

    my $data = $j->decode( $json_req );

    my $authenticated = eval {
        $c->authenticate({ username => $data->{ 'username' },
                           password => $data->{ 'password' }, });
    };
    if ( $@ ) {
        $c->log->error("login authentication error: $@");
        $c->res->status('503');
        $c->stash->{ 'message' } = 'Authentication service unavailable. Please try again later.';
        $c->stash->{ 'success' } = JSON->false();
        $c->forward( 'View::JSON' );
    }
    elsif ( $authenticated ) {

	    $c->log->info("login authentication of user '" . $data->{ 'username' } . "' successful.");
        $c->user->update({ date_accessed => \'CURRENT_TIMESTAMP' });

        # ExtJS form redirects to url_success_target URI.
	    $c->res->status('200');
        $c->stash->{ 'success' } = JSON()->true();
        $c->forward( 'View::JSON' );
    }
    else {

	    $c->log->info("login authentication of user '" . $data->{ 'username' } . "' failed.");

        $c->res->status('401');
        $c->stash->{ 'message' } = 'Login failed.';
        $c->stash->{ 'success' } = JSON()->false();
        $c->forward( 'View::JSON' );
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
    $c->stash->{ 'success' } = JSON()->true();
    $c->res->redirect( $c->uri_for('/') );
}

=head2 json_logout

A method which simply deauthenticates the user without redirecting to
the root page (so that the stashed success message can be retrieved).

=cut

sub json_logout : Global {

    my ( $self, $c ) = @_;

    $c->logout;
    
    $c->flash->{ 'message' } = 'Successfully logged out.';
    $c->stash->{ 'success' } = JSON()->true();
    $c->detach( $c->view( 'JSON' ) );
}

=head2 auto

Automatically called for each request. Ensures HTTPS is used unless in 
testing mode, and that the request method is GET/HEAD/POST.

=cut

sub auto : Private {

    my ($self, $c) = @_;

    # 404 unless https/testing & request method is GET/HEAD/POST
    unless( ( $c->req->secure or $c->config->{testing} == 1 )
            && grep /^(?:GET|HEAD|POST)$/, $c->req->method )
        {
            $c->detach('default');
        }

    # Prepend all uri_for paths so that this works under a reverse proxy.
    my $base = $c->config->{ 'base_path' };
    if ( defined $base ) {
        my $uri = $c->req->base;
        $uri->path($base);
        $c->req->base($uri);
        $c->stash->{'base_path'} = $base;
    }

    # Return true to continue processing.
    return 1;
}

=head2 end

Attempt to render a view, if needed. Sets security headers on all responses.

=cut 

sub end : ActionClass('RenderView') {

    my ($self, $c) = @_;

    # don't require TLS for testing
    unless ($c->config->{testing} == 1) {
        $c->response->header('Strict-Transport-Security' => 'max-age=3600; includeSubDomains');
    }

    $c->response->header(
        'X-Frame-Options'           => 'SAMEORIGIN',
        'Content-Security-Policy'   => "default-src 'none'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; frame-ancestors 'self'; form-action 'self';",
        'X-Content-Type-Options'    => 'nosniff',
        'X-Download-Options'        => 'noopen',
        'X-XSS-Protection'          => "1; 'mode=block'",
        'Referrer-Policy'           => "strict-origin-when-cross-origin",
        'Permissions-Policy'        => "geolocation=(), microphone=(), camera=()",
        'X-CSRF-Token'              => $c->csrf_token, # Expose CSRF token in header for JavaScript clients
    );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
