use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::OrderBatch' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/orderbatch',
            'OrderBatch index should succeed' );

$ua->get_ok('/orderbatch/list/1',
            'OrderBatch list should succeed' );

# Not implemented FIXME if needed
#$ua->get_ok('/orderbatch/grid/1',
#            'OrderBatch grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/orderbatch/submit', 'OrderBatch submit should succeed' );
#$ua->get_ok('/orderbatch/delete', 'OrderBatch delete should succeed' );

done_testing();
