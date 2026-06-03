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

package BeerFestDB::Web;

use strict;
use warnings;

use Catalyst::Runtime 5.90;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/ConfigLoader
                Static::Simple

                Session
                Session::State::Cookie
                Session::Store::FastMmap

                Authentication
                Authorization::Roles
                Authorization::ACL

                CSRFToken
               /;
our $VERSION = '1.2';

# Configure the application. 
#
# Note that settings in beerfestdb_web.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name         => 'BeerFestDB::Web',
    default_view => 'HTML',
    encoding     => 'UTF-8',
    session => { flash_to_stash => 1,
                 expires        => 3600, },
    'Plugin::Session' => {
        storage => "/tmp/beerfestdb-$>/web/session_data",
        unlink_on_exit => 1,
    },
    'Plugin::OpenIDConnect' => {
        user_claims => {
            sub => 'id',
            name => 'name',
            email => 'email',
            preferred_username => 'username',
        },
        debug => 0, # Set to 1 for specific logging of OIDC plugin including setup.
    },
    authentication => {  
        default_realm => 'beerfestdb',
        realms => {
            beerfestdb => {
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'salted_hash',
                    password_salt_len => 4,
                },
                store => {
                    class         => 'DBIx::Class',
                    user_class    => 'DB::User',
                    id_field      => 'user_id',
                    role_relation => 'roles',
                    role_field    => 'rolename',
                }
            },
        }
    },
    'Plugin::CSRFToken' => {
        'max_age' => 3600, # Token lifespan in seconds
        'auto_check' => 1,
        'default_secret' => 'a very long and secret string that should be overridden in production',
    },
    default_currency    => 'GBP',
    default_sale_volume => 'pint',
    default_product_category => 'beer',
    default_measurement_unit => 'gallon',
    stock_control_departments => [],
    awrs_urn_prefix => 'https://www.tax.service.gov.uk/check-the-awrs-register?query=',
    using_frontend_proxy => 1,  # create URLs using HTTPS scheme when behind a proxy
    enable_catalyst_header => 0,  # Disable X-Catalyst header
    testing => 0,  # Set to 1 to disable HTTPS requirement for testing.
 );

# Load the OpenIDConnect plugin if available. ConditionalOIDC runs its
# after-setup hook between ConfigLoader and OpenIDConnect: it checks that
# the configured key files are readable and, if not, removes the issuer
# config so that the OpenIDConnect plugin skips initialisation gracefully
# instead of dying. Both plugins must be passed to setup() together so
# that the Moose after-modifier ordering is correct (ConditionalOIDC inner,
# OpenIDConnect outer).
my $has_openid_connect_plugin = eval { require Catalyst::Plugin::OpenIDConnect; 1; };
if ( $has_openid_connect_plugin ) {
    __PACKAGE__->setup(qw/+BeerFestDB::Web::Plugin::ConditionalOIDC OpenIDConnect/);
}
else {
    __PACKAGE__->setup();
}

# Turn off debug output unless we're really debugging.
__PACKAGE__->log->levels( qw/info warn error fatal/ ) unless __PACKAGE__->debug;

# Access control. First, general areas which are editable by users
# (product category level authorization handled in the Controller base
# class).
foreach my $path ( qw(bar caskmeasurement cask company
                      contact festival festivalproduct gyle
                      measurementbatch orderbatch productorder
                      product stillagelocation telephone) ) {
    __PACKAGE__->allow_access_if( '/' . $path, [ qw( user ) ] );
    __PACKAGE__->deny_access( '/' . $path );
}

# Controlled vocabs only editable by admin (but which must be listable by all users).
foreach my $path ( qw(productstyle productcharacteristictype) ) {
    __PACKAGE__->allow_access_if( "/$path/list_by_category", [ qw( user ) ] );
}
foreach my $path ( qw(bayposition companyregion contacttype containermeasure
                      containersize country currency dispensemethod
                      productallergentype productcharacteristictype
                      productcategory productstyle role
                      salevolume telephonetype) ) {
    __PACKAGE__->allow_access_if( "/$path/list", [ qw( user ) ] );
    __PACKAGE__->allow_access_if( '/' . $path, [ qw( admin ) ] );
    __PACKAGE__->deny_access( '/' . $path );
}

# Special handling for user management: users can edit their own account but only admins
# can edit other accounts or assign roles.
__PACKAGE__->allow_access_if( '/user', [ qw( admin ) ] );
__PACKAGE__->allow_access( '/user/modify' );                 # User-level account modification.
__PACKAGE__->allow_access( '/user/load_form' );              # Maintains its own access config.
__PACKAGE__->allow_access( '/user/view' );                   # Ownership checked in action.
__PACKAGE__->allow_access( '/user/request_password_reset' ); # Ownership checked in action.
__PACKAGE__->allow_access( '/user/reset_password' );         # Token-based; no login required.
__PACKAGE__->allow_access( '/user/reset_password_submit' );  # Token-based; no login required.
__PACKAGE__->deny_access( '/user' );

# Areas to which access is always granted.
__PACKAGE__->allow_access( '/default' );
__PACKAGE__->allow_access( '/index' );
__PACKAGE__->allow_access( '/login' );

if ( $has_openid_connect_plugin ) {
    __PACKAGE__->allow_access( '/openidconnect' );
}

=head1 NAME

BeerFestDB::Web - Catalyst based application

=head1 SYNOPSIS

    script/beerfestdb_web_server.pl

=head1 DESCRIPTION

BeerFestDB is a product management system for beer festivals.

=head1 SEE ALSO

L<BeerFestDB::Web::Controller::Root>, L<Catalyst>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
