use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::SaleVolume' }

my $ua = authenticated_user("admin", "admin");

generic_grid_tests("salevolume", "SaleVolume", $ua);

$ua->get_ok('/salevolume/view/1',
            'SaleVolume view should succeed' );

done_testing();
