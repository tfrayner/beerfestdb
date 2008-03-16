# $Id$

use strict;
use warnings;

package BeerFestDB::Config;

use Config::YAML;
use File::Spec;

use base qw(Exporter);
our @EXPORT_OK = qw($CONFIG);

my $userconf = File::Spec->catpath( undef, $ENV{HOME}, '.beerfestdb.conf' );

# Write a new config file on the first run.
unless ( -f $userconf ) {
    open ( my $conf, '>', $userconf )
	or die("Error opening config file $userconf for writing: $!");
    while ( my $line = <DATA> ) {
	print $conf $line;
    }
    close( $conf );
    print(  "A new configuration file has been written to $userconf\n"
	  . "Please edit it and then re-run this script.\n");
    exit 255;
}

# Read in our config.
our $CONFIG = Config::YAML->new(
    config => $userconf,
);

1;

__DATA__
# BeerFestDB Configuration File.

# This is an example config file. It was automatically copied to your
# home directory the first time you ran the autoload script. Please
# edit as necessary.

host:       localhost
database:   beerfestdb
port:       3306
username:   test
password:   test
