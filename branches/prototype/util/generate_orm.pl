# $Id$

use strict;
use warnings;

package BeerFestDB::ORM;

# We use this to load our classes for now.
use base qw(DBIx::Class::Schema::Loader);

use BeerFestDB::Config qw( $CONFIG );

__PACKAGE__->loader_options(
    debug => $CONFIG->get_debug(),
);

package main;

use BeerFestDB::Config qw( $CONFIG );

use Getopt::Long;

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

my ( $dir );

GetOptions(
    "d|directory=s" => \$dir,
);

unless ( $dir && -d $dir ) {

    print <<"USAGE";

Usage: $0 -d /orm/dump/directory

USAGE

    exit 255;
}

BeerFestDB::ORM->dump_to_dir($dir);
my $schema = connect_db();
