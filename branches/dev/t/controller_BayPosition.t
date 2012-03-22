use strict;
use warnings;
use Test::More;


use Catalyst::Test 'BeerFestDB::Web';
use BeerFestDB::Web::Controller::BayPosition;

ok( request('/bayposition')->is_success, 'Request should succeed' );
done_testing();
