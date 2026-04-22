use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);
use TestGenericGrid qw(generic_grid_tests);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::DispenseMethod' }

my $ua = authenticated_user("admin", "admin");

generic_grid_tests("dispensemethod", "DispenseMethod", $ua);

$ua->get_ok('/dispensemethod/view/1',
            'DispenseMethod view should succeed' );

$ua->get_ok('/dispensemethod/load_form',
            'DispenseMethod load_form should succeed' );

done_testing();
