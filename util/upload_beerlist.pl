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

package MyQueryClass;
use Moose;

use LWP;
use JSON::DWIW;

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
                            default  => sub { LWP::UserAgent->new() } );

has 'json_parser'      => ( is       => 'ro',
                            isa      => 'JSON::DWIW',
                            required => 1,
                            default  => sub { JSON::DWIW->new() } );

sub _find_festival_id {

    # FIXME it would be much quicker to run this search on the server.
    my ( $self ) = @_;

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

    my $fid = $self->_find_festival_id();
    my $cid = $self->_find_category_id();

    my $status_list = $self->_data_from_uri(
        sprintf('%s/festivalproduct/list_status/%s/%s', $self->uri(), $fid, $cid) );

    return $status_list;
}

sub _data_from_uri {

    my ( $self, $uri ) = @_;

    my $ua  = $self->useragent();
    my $res = $ua->get($uri);

    if ( ! $res->is_success() ) {
        die("Error: Unable to connect to BeerFestDB web site: " . $res->status_line() . " (" . $uri . ")");
    }

    my $json = $res->decoded_content();

    my $data = $self->json_parser->from_json($json);
    unless ( $data->{success} ) {
        die("Error: JSON query returned error: $data->{errorMessage}\n");
    }

    return( $data->{objects} );
}

#############
package main;

use Data::Dumper;
use Getopt::Long;
use Config::YAML;
use Pod::Usage;
use Template;
use Digest::SHA qw (hmac_sha256_hex);
use DateTime;
use DateTime::TimeZone;
use JSON::DWIW;

sub send_update {

    my ( $content, $uri, $clientid, $key ) = @_;

    $content     =~ s/[\r\n]//g;  # workaround for server bug
    my $counter  = time;
    my $mac      = hmac_sha256_hex($clientid . $counter . $content, $key);

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->post(
        $uri,
        [ 'clientid' => $clientid,
          'counter'  => $counter,
          'mac'      => $mac,
          'content'  => $content, ],
    );
    
    if ( ! $res->is_success() ) {
        die("Error: Unable to connect to Public web site: " . $res->status_line() );
    }

    return();
}

sub get_timestamp {

    my $dt = DateTime->now();
    my $tz = DateTime::TimeZone->new( name => 'local' );
    $dt->set_time_zone( $tz->name );

    return $dt->strftime("%a %b %e %Y %H:%M:%S %Z");
}

sub parse_args {

    my ( $conffile, $tfile, $json, $want_help );

    GetOptions(
        "c|config=s"   => \$conffile,
        "t|template=s" => \$tfile,
        "j|json"       => \$json,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $conffile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = Config::YAML->new( config => $conffile );

    my $template;
    if ( $tfile ) {
        open( my $fh, '<', $tfile )
            or die("Unable to open template file $tfile: $!\n");
        $template = join(q{}, <$fh>);
    }

    my $st = $config->{ status_query }
        or die("Error: No status_query section in config file.");

    return( $st, $template, $json );
}

my ( $config, $template, $use_json ) = parse_args();

# Check that the appropriate config parameters have been set
foreach my $item ( qw(festival_name
                      product_category
                      beerfestdb_uri
                      public_site_upload_uri
                      public_site_clientid
                      public_site_key) ) {
    unless ( defined $config->{ $item } ) {
        die(qq{Error: Config variable "$item" has not been set in the configuration file.});
    }
}

my $qobj = MyQueryClass->new(
    festival_name    => $config->{festival_name},
    product_category => $config->{product_category},
    uri              => $config->{beerfestdb_uri},
);

# Query the JSON API for latest status list.
my $statuslist = $qobj->query_status_list();

# Reorganise the status list by brewery.
my %brewery_info;
my %infomap = (  # Map internal tags to those used by beerengine etc.
    id          => 'id',
    product     => 'name',
    status      => 'status_text',
    abv         => 'abv',
    style       => 'style',
    description => 'notes',
    css_status  => 'css_status',
);
foreach my $item ( @$statuslist ) {
    my $id = $item->{company_id};
    $brewery_info{ $id }{id}           ||= $item->{company_id};
    $brewery_info{ $id }{name}         ||= $item->{company};
    $brewery_info{ $id }{location}     ||= $item->{location};
    $brewery_info{ $id }{year_founded} ||= $item->{year_founded};
    my ( $amount ) = ( $item->{status} =~ m/(\d+) \w+ Remaining/i );
    if ( defined $amount ) {
	if    ( $amount >= 18 ) {
	    $item->{status}     = 'Plenty left';
	    $item->{css_status} = 'plenty_left';
	}
	elsif ( $amount >= 9 ) {
	    $item->{status}     = 'Some beer remaining';
	    $item->{css_status} = 'some_beer_remaining';
	}
	elsif ( $amount >= 3 ) {
	    $item->{status}     = 'A little remaining';
	    $item->{css_status} = 'a_little_remaining';
	}
	else {
	    $item->{status}     = 'Nearly finished!';
	    $item->{css_status} = 'nearly_finished';	    
	}
    }
    push @{ $brewery_info{ $id }{products} },
        { map { $infomap{$_} => $item->{ $_ } } keys %infomap };
}

my $output;
if ( $use_json ) {

    # New version: generate a JSON-encoded string for upload.
    my $jwriter = JSON::DWIW->new();
    $output = $jwriter->to_json( { producers => [ values %brewery_info ],
                                   timestamp => get_timestamp() } );
}
else {

    # Generate the HTML fragment to upload.
    $template ||= join(q{}, <DATA>);
    
    # We define a custom title case filter for convenience.
    my $tt2 = Template->new(
        FILTERS => { titlecase => sub { join(' ', map { ucfirst $_ } split / +/, lc($_[0])) } }
    )   or die( "Cannot create Template object: " . Template->error() );
    
    $tt2->process(\$template,
                  { brewers   => [ values %brewery_info ],
                    timestamp => get_timestamp() },
                  \$output )
        or die( "Template processing error: " . $tt2->error() );
}

# Do the upload itself.
send_update($output,
            map { $config->{$_} }
                qw(public_site_upload_uri public_site_clientid public_site_key));

=head1 NAME

upload_beerlist.pl

=head1 SYNOPSIS

 upload_beerlist.pl -c beerfest_web.yml

=head1 DESCRIPTION

Local CBF-specific script used to upload the current beer list in XML
form to a public web site.

=head1 OPTIONS

=head2 -c

The path to the main BeerFestDB config file.

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
