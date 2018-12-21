use strict;
use warnings;
use Test::More;


use Catalyst::Test 'BeerFestDB::Web';
use BeerFestDB::Web::Controller::DispenseMethod;

ok( request('/dispensemethod')->is_success, 'Request should succeed' );
done_testing();
