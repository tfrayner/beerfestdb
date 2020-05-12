use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::Contact' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/contact/view/1',
            'Contact view should succeed' );

$ua->get_ok('/contact/load_form',
            'Contact load_form should succeed' );

$ua->get_ok('/contact/list_by_company/1',
            'Contact list_by_company should succeed' );

# Not yet implemented FIXME if needed.
#$ua->get_ok('/contact/grid/1',
#            'Contact grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/contact/submit', 'Contact submit should succeed' );
#$ua->get_ok('/contact/delete', 'Contact delete should succeed' );

done_testing();
