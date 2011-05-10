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
        die("Error: Unable to connect to BeerFestDB web site: " . $res->status_line() );
    }

    my $json = $res->decoded_content();
    my $data = $self->json_parser->from_json($json);

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

sub parse_args {

    my ( $conffile, $want_help );

    GetOptions(
        "c|config=s" => \$conffile,
        "h|help"     => \$want_help,
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

    return( $config->{ status_query }
                or die("Error: No status_query section in config file.") );
}

my ( $config ) = parse_args();

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
foreach my $item ( @$statuslist ) {
    my $brewer = $item->{company};
    $brewery_info{ $brewer }{name}         ||= $brewer;
    $brewery_info{ $brewer }{location}     ||= $item->{location};
    $brewery_info{ $brewer }{year_founded} ||= $item->{year_founded};
    push @{ $brewery_info{ $brewer }{beers} },
        { map { $_ => $item->{$_} } qw( product status abv description ) };
}

# Generate the XML fragment to upload.
my $template = join('', <DATA>);

# We define a custom title case filter for convenience.
my $tt2 = Template->new(
    FILTERS => { titlecase => sub { join(' ', map { ucfirst $_ } split / +/, lc($_[0])) } }
)   or die( "Cannot create Template object: " . Template->error() );

my $output;
$tt2->process(\$template, { brewers => [ values %brewery_info ] }, \$output )
    or die( "Template processing error: " . $tt2->error() );

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
  <div class="products">[% FOREACH beer = brewer.beers.sort('product') %]
    <span class="product">
      <span class="productname">[% beer.product | xml %]</span>
      <span class="abv">[% IF beer.abv.defined %][% beer.abv | xml %]%[% END %]</span>
      <span class="tasting">[% beer.description | xml %]</span>
      <span class="status">[% beer.status | xml %]</span>
    </span>
    [%- END %]
  </div>
[% END -%]
</div>
