use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::ContainerSize' }

my $ua = authenticated_user("admin", "admin");

generic_grid_tests("containersize", "ContainerSize", $ua);

$ua->get_ok('/containersize/view/1',
            'ContainerSize view should succeed' );

$ua->get_ok('/containersize/load_form',
            'ContainerSize load_form should succeed' );

done_testing();
