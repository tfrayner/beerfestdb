use strict;
use warnings;
use Test::More;

# Compile tests for modules not covered elsewhere.
# These modules depend on external services, interactive I/O, or complex
# runtime setup, so compile-time loading is the most practical test.

BEGIN {
    use_ok 'BeerFestDB::StillagePlanner';
    use_ok 'BeerFestDB::Dumper';
    use_ok 'BeerFestDB::Dumper::Template';
    use_ok 'BeerFestDB::Dumper::OODoc';
    use_ok 'BeerFestDB::Web::View::HTML';
    use_ok 'BeerFestDB::Web::Controller';
    use_ok 'BeerFestDB::Web::GenericGrid';
    use_ok 'BeerFestDB::Web::PriceController';
}

done_testing();
