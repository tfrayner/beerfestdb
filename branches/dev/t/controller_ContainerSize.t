use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::ContainerSize' }

ok( request('/containersize')->is_success, 'Request should succeed' );
done_testing();
