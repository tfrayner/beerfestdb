use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::ProductCategory' }

my $ua = authenticated_user("admin", "admin");

generic_grid_tests("productcategory", "ProductCategory", $ua);

done_testing();
