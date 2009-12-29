#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

package BeerFestDB::ORM;

# We use this to load our classes.
use base qw(DBIx::Class::Schema::Loader);

__PACKAGE__->loader_options(
#    debug => 1,
);

package main;

use Getopt::Long;
use Config::YAML;

my ( $dir, $conffile );

GetOptions(
    "d|directory=s" => \$dir,
    "c|config=s"    => \$conffile,
);

unless ( $dir && $conffile ) {

    print <<"USAGE";

Usage: $0 -d /orm/dump/directory -c beerfestdb_web.yml

USAGE

    exit 255;
}

my $config = Config::YAML->new( config => $conffile );
BeerFestDB::ORM->dump_to_dir($dir);
my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );
