#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

package BeerFestDB::Common;

use BeerFestDB::ORM;
use BeerFestDB::Config qw($CONFIG);

use base qw(Exporter);
our @EXPORT_OK = qw(connect_db);

sub connect_db {
    
    my $dsn = sprintf(
	"DBI:mysql:%s:%s:%s",
	$CONFIG->get_database(),
	$CONFIG->get_host(),
	$CONFIG->get_port(),
    );
    my $schema = BeerFestDB::ORM->connect(
	$dsn,
	$CONFIG->get_user(),
	$CONFIG->get_pass(),
	{ PrintError => 0, RaiseError => 1, AutoCommit => 1 },
    );

    return $schema;
}

1;
