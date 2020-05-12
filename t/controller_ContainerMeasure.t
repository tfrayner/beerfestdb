use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::ContainerMeasure' }

my $ua = authenticated_user("admin", "admin");

# grid not yet implemented FIXME if needed.
generic_grid_tests("containermeasure", "ContainerMeasure", $ua, 1);

done_testing();
