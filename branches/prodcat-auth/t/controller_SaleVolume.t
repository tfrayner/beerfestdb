use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::SaleVolume' }

ok( request('/salevolume')->is_success, 'Request should succeed' );
done_testing();
