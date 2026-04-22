use strict;
use warnings;
use Test::More;

# These roles depend on a live database connection or interactive I/O
# and are tested here for successful compilation only.
BEGIN { use_ok 'BeerFestDB::Role::CaskPreloader' }
BEGIN { use_ok 'BeerFestDB::Role::DipMunger'     }
BEGIN { use_ok 'BeerFestDB::Role::MenuSelector'  }

done_testing();
