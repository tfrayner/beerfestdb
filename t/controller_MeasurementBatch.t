use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestFestivalDB qw(authenticated_user);

BEGIN { use_ok 'Catalyst::Test', 'BeerFestDB::Web' }
BEGIN { use_ok 'BeerFestDB::Web::Controller::MeasurementBatch' }

my $ua = authenticated_user("cellar", "cellar");

# Using the fixtures set up in TestFestivalDB:
$ua->get_ok('/measurementbatch',
            'MeasurementBatch index should succeed' );

$ua->get_ok('/measurementbatch/view/1',
            'MeasurementBatch view should succeed' );

$ua->get_ok('/measurementbatch/list/1',
            'MeasurementBatch list should succeed' );

# Not implemented FIXME if needed.
#$ua->get_ok('/measurementbatch/grid/1',
#            'MeasurementBatch grid should succeed' );

# The following need JSON payloads and (in the case of delete) user confirmation.
#$ua->get_ok('/measurementbatch/submit', 'MeasurementBatch submit should succeed' );
#$ua->get_ok('/measurementbatch/delete', 'MeasurementBatch delete should succeed' );

done_testing();
