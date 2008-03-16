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

1;
