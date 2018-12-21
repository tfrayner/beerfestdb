use strict;
use warnings;
use Test::More;


use Catalyst::Test 'BeerFestDB::Web';
use BeerFestDB::Web::Controller::ProductAllergenType;

ok( request('/productallergentype')->is_success, 'Request should succeed' );
done_testing();
