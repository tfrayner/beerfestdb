use strict;
use warnings;
use Test::More;


use Catalyst::Test 'BeerFestDB::Web';
use BeerFestDB::Web::Controller::ContainerMeasure;

ok( request('/containermeasure')->is_success, 'Request should succeed' );
done_testing();
