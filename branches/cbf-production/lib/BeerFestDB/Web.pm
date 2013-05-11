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

package BeerFestDB::Web;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/ConfigLoader
                Unicode::Encoding
                Static::Simple

                Session
                Session::State::Cookie
                Session::Store::FastMmap

                Authentication
                Authorization::Roles
                Authorization::ACL
               /;
our $VERSION = '0.01';

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
    'View::JSON' => {
        json_driver => 'JSON::XS',
    },
    'Plugin::Session' => {
	storage => "/tmp/beerfestdb-$>/web/session_data",
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
    default_currency    => 'GBP',
    default_sale_volume => 'pint',
    default_product_category => 'beer',
 );

# Start the application
__PACKAGE__->setup();

# Access control.
foreach my $path ( qw(bar bayposition caskmeasurement cask company companyregion
                      contact contacttype containersize country currency festival
                      festivalproduct gyle measurementbatch orderbatch productcategory
                      productorder product productstyle salevolume stillagelocation
                      telephone telephonetype) ) {
    __PACKAGE__->allow_access_if( '/' . $path, [ qw( user ) ] );
    __PACKAGE__->deny_access( '/' . $path );
}

__PACKAGE__->allow_access_if( '/user', [ qw( admin ) ] );
__PACKAGE__->allow_access( '/user/modify' );    # User-level account modification.
__PACKAGE__->allow_access( '/user/load_form' ); # Maintains its own access config.
__PACKAGE__->deny_access( '/user' );

__PACKAGE__->allow_access_if( '/role', [ qw( admin ) ] );
__PACKAGE__->deny_access( '/role' );

# Areas to which access is always granted.
__PACKAGE__->allow_access( '/default' );
__PACKAGE__->allow_access( '/index' );
__PACKAGE__->allow_access( '/login' );

=head1 NAME

BeerFestDB::Web - Catalyst based application

=head1 SYNOPSIS

    script/beerfestdb_web_server.pl

=head1 DESCRIPTION

BeerFestDB is a product management system for beer festivals.

=head1 SEE ALSO

L<BeerFestDB::Web::Controller::Root>, L<Catalyst>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
