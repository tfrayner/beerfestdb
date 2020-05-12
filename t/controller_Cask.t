use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Cask' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/cask/view/1',
            'Cask view should succeed' );

$ua->get_ok('/cask/list/1/1',
            'Cask list should succeed' );

$ua->get_ok('/cask/grid/1/1',
            'Cask grid should succeed' );

$ua->get_ok('/cask/load_form',
            'Cask load_form should succeed' );

$ua->get_ok('/cask/list_by_stillage/1',
            'Cask list_by_stillage should succeed' );

$ua->get_ok('/cask/list_by_festival_product/1',
            'Cask list_by_festival_product should succeed' );

$ua->get_ok('/cask/list_dips/1',
            'Cask list_dips should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/cask/submit', 'Cask submit should succeed' );
#$ua->get_ok('/cask/delete', 'Cask delete should succeed' );
#$ua->get_ok('/cask/delete_from_stillage', 'Cask delete_from_stillage should succeed' );

done_testing();
