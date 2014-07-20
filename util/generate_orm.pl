#!/usr/bin/env perl
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

use strict;
use warnings;

package BeerFestDB::ORM;

# We use this to load our classes.
use base qw(DBIx::Class::Schema::Loader);

__PACKAGE__->loader_options(
#    debug => 1,
    exclude => qr/_view \z/xms,
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
