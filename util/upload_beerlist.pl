#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2011-2026 Tim F. Rayner
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

use strict;
use warnings;

binmode(STDOUT, ":utf8");

package MyQueryClass;
use Moose;

use LWP;
use HTTP::Cookies;
use JSON::MaybeXS;
use Term::ReadKey;
use Term::ReadLine;
use Encode;

use Moose::Util::TypeConstraints;

use BeerFestDB::Exceptions qw(UriAuthorizationError);

class_type 'JSON_XS', { class => 'Cpanel::JSON::XS' };
class_type 'JSON_PP', { class => 'JSON::PP' };

has 'uri'              => ( is       => 'ro',
                            isa      => 'Str',
                            required => 1 );

has 'festival_data'    => ( is       => 'rw',
                            isa      => 'HashRef',
                            required => 0,
                            default  => sub { {} } );

has 'useragent'        => ( is       => 'ro',
                            isa      => 'LWP::UserAgent',
                            required => 1,
                            default  => sub {
                                my $ua = LWP::UserAgent->new();
                                $ua->cookie_jar({});
                                return $ua;
                            } );

has 'json_parser'      => ( is       => 'ro',
                            isa      => 'JSON_XS | JSON_PP',
                            required => 1,
                            default  => sub { JSON::MaybeXS->new() } );

has 'debug'            => ( is       => 'ro',
                            isa      => 'Bool',
                            required => 1,
                            default  => 0 );

# Cache for credentials and IDs to avoid unnecessary queries and repeated credential prompts.
my $CREDENTIALS_CACHE = {};
my $FESTIVAL_CACHE = {};
my $CATEGORY_ID_CACHE = {};

sub _find_festival_id {

    my ( $self ) = @_;

    if ( defined $self->festival_data->{festival_id} ) {
        return $self->festival_data->{festival_id};
    }

    $self->debug && warn("Retrieving current festival...\n");

    my $fest_data = $self->_data_from_uri( $self->uri() . '/festival/current_festival', 'data' );

    my $festival_id = $fest_data->{festival_id}
        or die("Error: Unable to retrieve current festival ID from BeerFestDB web site.\n");

    $self->festival_data($fest_data);

    return $festival_id;
}

sub _find_category_id {

    # This is a slightly wasteful search through a listing of all product
    # categories, since we don't currently have a direct API query by prodcat
    # name. We cache the results to make this slightly less bad.
    my ( $self, $prodcat ) = @_;

    $self->debug && warn(sprintf("Searching category list for %s...\n", $prodcat));

    if ( exists $CATEGORY_ID_CACHE->{ $prodcat } ) {
        return $CATEGORY_ID_CACHE->{ $prodcat };
    }

    my $cat_list = $self->_data_from_uri( $self->uri() . '/productcategory/list' );

    # Make this search case-insensitive.
    foreach my $catref ( @$cat_list ) {
        if ( lc $catref->{description} eq lc $prodcat ) {
            $CATEGORY_ID_CACHE->{ $prodcat } = $catref->{product_category_id};
            return $catref->{product_category_id};
        }
    }

    die(qq{Error: Unable to find product category named "$prodcat".});
}

sub get_upload_departments {

    my ( $self ) = @_;

    $self->debug && warn(sprintf("Retrieving full product category list...\n"));

    my $cat_list = $self->_data_from_uri( $self->uri() . '/productcategory/list' );

    my @uploadable;

    # May as well pre-cache these results for later use, since we have them already.
    foreach my $catref( @$cat_list ) {
        $CATEGORY_ID_CACHE->{ $catref->{description} } = $catref->{product_category_id};
        if ( $catref->{is_status_public} ) {
            push @uploadable, $catref->{description};
        }
    }

    return \@uploadable;
}

sub query_status_list {

    my ( $self, $prodcat ) = @_;

    $self->debug && warn("Retrieving status list...\n");

    my $fid = $self->_find_festival_id();
    my $cid = $self->_find_category_id($prodcat);

    my $status_list = $self->_data_from_uri(
        sprintf('%s/festivalproduct/list_status/%s/%s', $self->uri(), $fid, $cid) );

    return $status_list;
}

sub _retrieve_credentials {

    my ( $self ) = @_;

    if ( my $username = $CREDENTIALS_CACHE->{username} ) {
        return map { $CREDENTIALS_CACHE->{$_} } qw(username password);
    }

    print STDERR ("BeerFestDB username: ");
    chomp( my $username = <STDIN> );

    ReadMode 2;
    print STDERR ("BeerFestDB password: ");
    chomp( my $password = <STDIN> );
    ReadMode 0;
    print STDERR ("\n");

    $CREDENTIALS_CACHE->{username} = $username;
    $CREDENTIALS_CACHE->{password} = $password;

    return( $username, $password );
}

sub _attempt_login {

    my ( $self ) = @_;

    $self->debug && warn("Attempting login...\n");

    my ( $username, $password ) = $self->_retrieve_credentials();

    my $ua   = $self->useragent();
    my $json = $self->json_parser()->encode({
        username => $username,
        password => $password,
    });

    # Get the login page first to set cookies, then post the login data.
    my $preres = $ua->get( sprintf('%s/login', $self->uri()) );
    my $headers = $preres->headers();
    my $csrf_token = $headers->header('X-CSRF-Token') || '';

    # We should only need the CSRF token for this one post operation.
    my $res = $ua->post( sprintf('%s/login', $self->uri()),
                         { data => $json, csrf_token => $csrf_token } );

    if ( $res->is_error() ) {  # Allows redirects.
        die("Error: Unable to login to BeerFestDB web site: "
                . $res->status_line() . " (" . $res->decoded_content() . "; " . $self->uri() . ")\n");
    }
    my $login = $self->json_parser->decode( decode("UTF-8", $res->decoded_content()) );
    unless ( $login->{success} ) {
        die("Error: Unable to login to BeerFestDB web site: "
                . $res->status_line() . " (" . $res->decoded_content() . "; " . $self->uri() . ")\n");
    }

    return;
}

sub _data_from_uri {

    my ( $self, $uri, $field ) = @_;

    $field ||= 'objects';

    my $ua  = $self->useragent();

    my $res;
    foreach my $run ( 1, 2 ) {
        
        # Run the query
        $res = $ua->get($uri);
        
        # Handle errors. If 403, try logging in once and retrying. Otherwise, die.
        if ( ! $res->is_success() ) {
            if ( $res->code() == 403 ) {

                # Try logging in once only.
                if ( $run == 1 ) {
                    $self->_attempt_login();
                }
                else {
                    # Catchable exception
                    UriAuthorizationError->throw(
                        uri => $uri,
                        message => "User is not authorized to access $uri.\n"
                    );
                }
            }
            else {
                die("Error: Unable to connect to BeerFestDB web site: "
                        . $res->status_line() . " (" . $uri . ")\n");
            }
        } else {
            # Success, so break out of the loop.
            last;
        }
    }

    my $json = decode("UTF-8", $res->decoded_content());

    my $data = $self->json_parser->decode($json);
    unless ( $data->{success} ) {
        die("Error: JSON query returned error: $data->{error}\n");
    }

    # Escape all newlines to avoid problems with JSON parsers which don't handle them in strings.
    my $objdata = $data->{$field};
    $objdata =~ s/\n/\\n/g;

    return( $objdata );
}

#############
package main;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Template;
use Digest::SHA qw (hmac_sha256_hex);
use DateTime;
use DateTime::TimeZone;
use JSON::MaybeXS;
use List::Util qw (first);
use BeerFestDB::Web;
use Encode qw(encode_utf8);
use URI;
use Carp;
use Try::Tiny::ByClass;
use BeerFestDB::Exceptions qw(UriAuthorizationError);
use HTTP::CookieJar::LWP;

use utf8;

sub send_update {

    my ( $content, $uri, $festival_tag, $dept, $debug ) = @_;

    $debug && warn("Uploading content...\n");

    $content =~ s/[\r\n]//g;  # workaround for server bug

    my $upload_uri = URI->new($uri);

    my %dispatch = (
        file  => \&_update_via_local_command,
# Alternative upload schemes yet to be implemented:
#        http  => \&_update_via_web_upload,
#        https => \&_update_via_web_upload,
    );

    my $scheme = $upload_uri->scheme();
    if ( ! exists $dispatch{ $scheme } ) {
        croak("Data upload scheme not recognised: '" . $upload_uri->scheme()
	      . "'\nShould be one of: " . join(", ", keys %dispatch) . "\n" );
    }
    $dispatch{$scheme}->( $upload_uri, $content, $festival_tag, $dept ) unless $debug;

    return();
}

sub _update_via_local_command {

    my ( $uri, $content, $festival_tag, $dept ) = @_;

    $dept =~ s/ /-/g; # as requested by public site team.

    my $cmd = $uri->path;
    $cmd =~ s/%20/ /g;

    # Validate command path to ensure it's an absolute path and exists
    unless ( -x $cmd ) {
        die("Invalid command path: $cmd is not executable!");
    }

    # Validate festival_tag and dept to contain only safe characters
    unless ( $festival_tag =~ /^[a-zA-Z0-9_-]+$/ ) {
        die("Invalid festival_tag: contains unsafe characters!");
    }
    unless ( $dept =~ /^[a-zA-Z0-9_-]+$/ ) {
        die("Invalid dept: contains unsafe characters!");
    }

    # This assumes that the command accepts '-' as designating input
    # from stdin. Use list form of open to avoid shell interpretation.
    open ( my $pipe, '|-', $cmd, $festival_tag, $dept, '-' )
        or die("Unable to open command pipe: $!");

    binmode($pipe, ":utf8");

    print $pipe $content;

    return();
}

sub get_timestamp {

    my $dt = DateTime->now();
    my $tz = DateTime::TimeZone->new( name => 'local' );
    $dt->set_time_zone( $tz->name );

    return $dt->strftime("%a %b %e %Y %H:%M:%S %Z");
}

sub update_brewery_info {

    my ( $brewery_info, $statuslist, $prodcat ) = @_;

    # Reorganise the status list by brewery.
    my %infomap = (  # Map internal tags to those used by beerengine etc.
        id          => 'id',
        product     => 'name',
        status      => 'status_text',
        abv         => 'abv',
        style       => 'style',
        is_vegan    => 'is_vegan',
        long_description => 'notes',
        allergens   => 'allergens',
        stillage_location => 'bar',
        dispense_method   => 'dispense',
    );
    my @boolean_fields = qw(is_vegan);
    foreach my $item ( @$statuslist ) {
        my $id = $item->{company_id};
        $brewery_info->{ $id }{id}           ||= $item->{company_id};
        $brewery_info->{ $id }{name}         ||= $item->{company};
        my $notes = $item->{location};
        $notes .= ' ' if ( defined $notes && $notes ne q{} );
        $notes .= "est. $item->{year_founded}" if defined $item->{year_founded};
        $brewery_info->{ $id }{notes}        ||= $notes;
        $brewery_info->{ $id }{location}     ||= $item->{location};
        $brewery_info->{ $id }{year_founded} ||= $item->{year_founded};
        my ( $amount ) = ( $item->{status} =~ m/(\d+) \w+ Remaining/i );
        my $starting   = $item->{starting_volume} || 36; # default is 2 kils
        if ( defined $amount ) {
            if    ( $amount >= $starting / 2 ) {
                $item->{status}     = 'Plenty left';
                $item->{css_status} = 'plenty_left';
            }
            elsif ( $amount >= $starting / 4 ) {
                $item->{status}     = 'Some beer remaining';
                $item->{css_status} = 'some_beer_remaining';
            }
            elsif ( $amount >= $starting / 12 ) {
                $item->{status}     = 'A little remaining';
                $item->{css_status} = 'a_little_remaining';
            }
            else {
                $item->{status}     = 'Nearly finished!';
                $item->{css_status} = 'nearly_finished';
            }
        }

        # Suppress status reports for departments which aren't
        # currently stocktaking using the database.
        if ( first { $_ eq lc $prodcat }
                 ('cider', 'perry', 'apple juice', 'mead', 'wine') ) {
            $item->{status} = '';
        }
        my $beer_info = { map { $infomap{$_} => $item->{ $_ } } keys %infomap };

        foreach my $boolfield ( @boolean_fields ) {
            if ( defined $beer_info->{ $boolfield } ) {
                $beer_info->{ $boolfield } = $beer_info->{ $boolfield } 
                                           ? JSON::MaybeXS->true 
                                           : JSON::MaybeXS->false;
            }
        }

        if ( $prodcat eq 'apple juice' ) {
            $beer_info->{name} .= ' APPLE JUICE';
        }

        # If long_description not available, fall back to short description.
        if ( ! defined $beer_info->{notes} || $beer_info->{notes} eq q{} ) {
            $beer_info->{notes} = $item->{description}
        }

        $beer_info->{category} = $prodcat;

        push @{ $brewery_info->{ $id }{products} }, $beer_info;
    }

    # One last sort by product name.
    foreach my $id ( keys %$brewery_info ) {
	$brewery_info->{ $id }{products} = [ 
	    map { $_->[0] }
	    sort { $a->[1] cmp $b->[1] }
	    map { [ $_, $_->{name} ] }
	    @{ $brewery_info->{ $id }{products} }
	];
    }
}

sub parse_args {

    my ( $debug, $want_help );

    GetOptions(
        "d|debug"      => \$debug,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    my $config = BeerFestDB::Web->config();

    my $st = $config->{ status_query }
        or die("Error: No status_query section in config file.");

    return( $st, $debug );
}

sub upload_department {

    my ( $prodcat, $config, $qobj, $debug ) = @_;

    my $brewery_info = {};

    # Query the JSON API for latest status list.
    my $statuslist;
    try {
        $statuslist = $qobj->query_status_list($prodcat);
    }
    catch_case [
         'BeerFestDB::Exceptions::UriAuthorizationError' => sub {
            my ($e) = @_;
            warn("Warning: Logged in user is unable to access listing for $prodcat.\n");
            return;
        },
    ];

    update_brewery_info( $brewery_info, $statuslist, $prodcat );

    if ( ! scalar grep { defined $_ } values %$brewery_info ) {
        warn("No festival data retrieved for $prodcat; skipping.\n");
        return;
    }

    # Default version: generate a JSON-encoded string for upload.
    my $jwriter = JSON::MaybeXS->new();
    my @content = map { $_->[0] } # Schwartzian transform sorting by brewery name.
                  sort { $a->[1] cmp $b->[1] }
                  map { [ $_, $_->{name} ] }
                  values %$brewery_info;
    my $output = $jwriter->encode( { producers => \@content,
				                     timestamp => get_timestamp() } );

    # Check for valid UTF-8 (don't just trust MySQL, although I've no reason to doubt it yet).
    unless (utf8::valid($output)) {
        die("Error: Database generated non-UTF8 output");
    }

    # Warn on unusual/new characters. Add new characters here only if
    # you're sure the server can handle it. FIXME less important now we're using XML::Entities.
#    my $core_re = qr/[^[:alnum:]_&\$"'+.,!?:;(){}\[\]%\/\\âëöäüáéÄçßøπ°·žĀě \*\#-]+/;
#    my $re = qr/( .{0,8} $core_re .{0,8} )/xms;
#    if ( $output =~ $re ) {
#        warn("Warning: uploaded content contains unexpected characters and may fail."
#           . " Context follows:\n\n$1\n\n"
#           . "If failure occurs, try using -d to examine the upload string.\n");
#    }

    $debug && print STDOUT "\n$output\n";

    printf STDERR ("Uploading data for %s...\n", $prodcat);

    # Do the upload itself. This may fail but should not block
    # department updates subsequently listed in the config file.
    # FIXME config public_festival_tag is deprecated and will be
    # removed in future; the festival tag is now retrieved from the BeerFestDB web site.
    eval {
        send_update($output,
                    $config->{'public_site_upload_uri'},
                    $qobj->festival_data->{public_status_tag} || $config->{'public_festival_tag'},
                    $prodcat,
                    $debug);
    };
    if ( $@ ) {
        warn(qq{Error encountered during dept. update: $@});
    }
}

my ( $config, $debug ) = parse_args();

# Check that the appropriate config parameters have been set
foreach my $item ( qw(beerfestdb_uri
                      public_site_upload_uri) ) {
    unless ( defined $config->{ $item } ) {
        die(qq{Error: Config variable "$item" has not been set in the configuration file.});
    }
}

# Just one user agent for the whole run, to preserve cookies and avoid unnecessary overhead.
my $ua = LWP::UserAgent->new(cookie_jar_class => 'HTTP::CookieJar::LWP');
$ua->cookie_jar({});

my $qobj = MyQueryClass->new(
    uri              => $config->{beerfestdb_uri},
    useragent        => $ua,
    debug            => $debug,
);

my $departments = $qobj->get_upload_departments();

foreach my $dept ( @{ $departments } ) {
    upload_department($dept, $config, $qobj, $debug);
}

=head1 NAME

upload_beerlist.pl

=head1 SYNOPSIS

 upload_beerlist.pl

=head1 DESCRIPTION

Local CBF-specific script used to upload the current beer list in XML
form to a public web site.

=head1 OPTIONS

=head2 -d

(Optional) Enable debug mode. The payload will be printed to STDOUT, and nothing 
will be uploaded if this option is specified.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

