use strict;
use warnings;
use Test::More;

# Note this controller will not load if the (optional) plugin is not installed and configured.
BEGIN { use_ok 'BeerFestDB::Web::Controller::OpenIDConnect' }

done_testing();
