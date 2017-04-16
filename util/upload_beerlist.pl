#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2011 Tim F. Rayner
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
use JSON::DWIW;
use Term::ReadKey;
use Term::ReadLine;

has 'uri'              => ( is       => 'ro',
                            isa      => 'Str',
                            required => 1 );

has 'festival_name'    => ( is       => 'ro',
                            isa      => 'Str',
                            required => 1 );

has 'product_category' => ( is       => 'ro',
                            isa      => 'Str',
                            required => 1 );

has 'useragent'        => ( is       => 'ro',
                            isa      => 'LWP::UserAgent',
                            required => 1,
                            default  => sub {
                                my $ua = LWP::UserAgent->new();
                                $ua->cookie_jar({});
                                return $ua;
                            } );

has 'json_parser'      => ( is       => 'ro',
                            isa      => 'JSON::DWIW',
                            required => 1,
                            default  => sub { JSON::DWIW->new() } );

has 'debug'            => ( is       => 'ro',
                            isa      => 'Bool',
                            required => 1,
                            default  => 0 );

my $CREDENTIALS_CACHE = {};

sub _find_festival_id {

    # FIXME it would be much quicker to run this search on the server.
    my ( $self ) = @_;

    $self->debug && warn("Retrieving festival list...\n");

    my $fest_name = $self->festival_name();
    my $fest_list = $self->_data_from_uri( $self->uri() . '/festival/list' );

    # Make this search case-insensitive.
    foreach my $festref ( @$fest_list ) {
        if ( lc $festref->{name} eq lc $fest_name ) {
            return $festref->{festival_id};
        }
    }

    die(qq{Error: Unable to find festival named "$fest_name".});
}

sub _find_category_id {

    # FIXME it would be much quicker to run this search on the server.
    my ( $self ) = @_;

    $self->debug && warn("Retrieving category list...\n");

    my $prod_cat = $self->product_category();
    my $cat_list = $self->_data_from_uri( $self->uri() . '/productcategory/list' );

    # Make this search case-insensitive.
    foreach my $catref ( @$cat_list ) {
        if ( lc $catref->{description} eq lc $prod_cat ) {
            return $catref->{product_category_id};
        }
    }

    die(qq{Error: Unable to find product category named "$prod_cat".});
}

sub query_status_list {

    my ( $self ) = @_;

    $self->debug && warn("Retrieving status list...\n");

    my $fid = $self->_find_festival_id();
    my $cid = $self->_find_category_id();

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
    my $json = $self->json_parser()->to_json({
        username => $username,
        password => $password,
    });
    my $res = $ua->post( sprintf('%s/login', $self->uri()),
                         { data => $json });

    if ( $res->is_error() ) {  # Allows redirects.
        die("Error: Unable to login to BeerFestDB web site: "
                . $res->status_line() . " (" . $self->uri() . ")\n");
    }
    my $login = $self->json_parser->from_json( $res->decoded_content() );
    unless ( $login->{success} ) {
        die("Error: Unable to login to BeerFestDB web site: "
                . $res->status_line() . " (" . $self->uri() . ")\n");                
    }

    return;
}

sub _data_from_uri {

    my ( $self, $uri ) = @_;

    my $ua  = $self->useragent();
    my $res = $ua->get($uri);

    if ( ! $res->is_success() ) {
        if ( $res->code() == 403 ) {

            # Try logging in once only.
            $self->_attempt_login();

            # Retry the original query.
            $res = $ua->get($uri);
            if ( ! $res->is_success() ) {
                die("Error: Logged in user unable to access requested URI: "
                        . $res->status_line() . " (" . $uri . ")\n");
            }
        }
        else {
            die("Error: Unable to connect to BeerFestDB web site: "
                    . $res->status_line() . " (" . $uri . ")\n");
        }
    }

    my $json = $res->decoded_content();

    my $data = $self->json_parser->from_json($json);
    unless ( $data->{success} ) {
        die("Error: JSON query returned error: $data->{error}\n");
    }

    return( $data->{objects} );
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
use JSON::DWIW;
use List::Util qw (first);
use BeerFestDB::Web;
use Encode qw(encode_utf8);
use URI;
use Carp;

use utf8;

sub send_update {

    my ( $content, $uri, $festival_tag, $dept, $debug ) = @_;

    $debug && warn("Uploading content...\n");

    $content =~ s/[\r\n]//g;  # workaround for server bug

    my $upload_uri = URI->new($uri);

    my %dispatch = (
        file  => \&_update_via_local_command,
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

    # This assumes that the command accepts '-' as designating input
    # from stdin.
    open ( my $pipe, "| $cmd $festival_tag $dept -" )
        or die("Unable to open command pipe: $!");

    binmode($pipe, ":utf8");

    print $pipe $content;

    return();
}

# No longer supported, this remains for now as a record of how the old
# beerengine upload worked.

# sub _update_via_web_upload {

#     my ( $uri, $content, $clientid, $key ) = @_;

#     my $counter  = time;
#     my $mac      = hmac_sha256_hex(encode_utf8($clientid . $counter . $content), $key);

#     my $ua  = LWP::UserAgent->new;
#     my $res = $ua->post(
#         $uri,
#         [ 'clientid' => $clientid,
#           'counter'  => $counter,
#           'mac'      => $mac,
#           'content'  => $content, ],
#     );

#     if ( ! $res->is_success() ) {
#         die(sprintf("Error: Unable to connect to Public web site: %s\nResponse content:\n  %s",
#                     $res->status_line(), $res->content() ));
#     }

#     return();
# }

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
        long_description => 'notes',
        allergens   => 'allergens',
        stillage_location => 'bar',
        dispense_method   => 'dispense',
    );
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

    my ( $tfile, $debug, $want_help );

    GetOptions(
        "t|template=s" => \$tfile,
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

    my $template;
    if ( $tfile ) {
        open( my $fh, '<', $tfile )
            or die("Unable to open template file $tfile: $!\n");
        $template = join(q{}, <$fh>);
    }

    my $st = $config->{ status_query }
        or die("Error: No status_query section in config file.");

    # We don't really want to set this twice.
    $st->{ festival_name } ||= $config->{ current_festival };

    return( $st, $template, $debug );
}

sub upload_department {

    my ( $prodcat, $config, $template, $debug ) = @_;

    my $brewery_info = {};

    my $qobj = MyQueryClass->new(
        festival_name    => $config->{festival_name},
        product_category => $prodcat,
        uri              => $config->{beerfestdb_uri},
        debug            => $debug,
    );

    # Query the JSON API for latest status list.
    my $statuslist = $qobj->query_status_list();

    update_brewery_info( $brewery_info, $statuslist, $prodcat );

    if ( ! scalar grep { defined $_ } values %$brewery_info ) {
        warn("No festival data retrieved for $prodcat; skipping.\n");
        return;
    }

    # Default version: generate a JSON-encoded string for upload.
    my $jwriter = JSON::DWIW->new();
    my @content = map { $_->[0] } # Schwartzian transform sorting by brewery name.
                  sort { $a->[1] cmp $b->[1] }
                  map { [ $_, $_->{name} ] }
                  values %$brewery_info;
    my $output = $jwriter->to_json( { producers => \@content,
				      timestamp => get_timestamp() } );

    # Check for valid UTF-8 (don't just trust MySQL, although I've no reason to doubt it yet).
    unless (utf8::valid($output)) {
        die("Error: Database generated non-UTF8 output");
    }

    # Warn on unusual/new characters. Add new characters here only if
    # you're sure the server can handle it.
    my $core_re = qr/[^[:alnum:]_&"'+.,!?:;(){}\[\]%\/\\âëöäüáéÄπ° \*-]+/;
    my $re = qr/( .{0,8} $core_re .{0,8} )/xms;
    if ( $output =~ $re ) {
        warn("Warning: uploaded content contains unexpected characters and may fail."
           . " Context follows:\n\n$1\n\n"
           . "If failure occurs, try using -d to examine the upload string.\n");
    }

    $debug && print STDOUT "\n$output\n";

    printf STDERR ("Uploading data for %s...\n", $prodcat);

    # Do the upload itself. This may fail but should not block
    # department updates subsequently listed in the config file.
    eval {
        send_update($output,
                    $config->{'public_site_upload_uri'},
                    $config->{'public_festival_tag'},
                    $prodcat,
                    $debug);
    };
    if ( $@ ) {
        warn(qq{Error encountered during dept. update: $@});
    }
}

my ( $config, $template, $debug ) = parse_args();

# Check that the appropriate config parameters have been set
foreach my $item ( qw(festival_name
                      departments
                      beerfestdb_uri
                      public_site_upload_uri
                      public_festival_tag) ) {
    unless ( defined $config->{ $item } ) {
        die(qq{Error: Config variable "$item" has not been set in the configuration file.});
    }
}

foreach my $dept ( @{ $config->{departments} } ) {
    upload_department($dept, $config, $template, $debug)
}

=head1 NAME

upload_beerlist.pl

=head1 SYNOPSIS

 upload_beerlist.pl

=head1 DESCRIPTION

Local CBF-specific script used to upload the current beer list in XML
form to a public web site.

=head1 OPTIONS

=head2 -t

(Optional) A path to an alternate template file. If omitted, a suitable default will be provided.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

#
# What follows under __DATA__ is the output template.
#

__DATA__
<div class="beerlist">
[%- FOREACH brewer = brewers.sort('name') %]
  <span class="producer">[% brewer.name | xml %]<span class="brewerydetails">[% brewer.location | xml %][% IF brewer.year_founded && brewer.year_founded + 0 %] est. [% brewer.year_founded | xml %][% END %]</span></span>
  <div class="products">[% FOREACH beer = brewer.products.sort('product') %]
    <span class="product">[% IF beer.css_status == 'sold_out' %]<span class="product_[% beer.css_status %]">[% END %]
      <span class="productname">[% beer.name | xml %]</span>
      <span class="abv">[% IF beer.abv.defined %][% beer.abv | xml %]%[% END %]</span>
      <span class="tasting">[% beer.notes | xml %]</span>
      <span class="status_[% beer.css_status %]">[% beer.status_text | xml %]</span>
    </span>
    [%- END %]
  </div>
[% END -%]
</div>

<span class="timestamp"><br/>Last updated: [% timestamp %]</span>
