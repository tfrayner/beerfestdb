use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
use IO::File;

use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Dumper::Template' }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# A minimal TT template: one product name per line.
my ( undef, $tt_file ) = tempfile( SUFFIX => '.tt2', UNLINK => 1 );
{
    open my $fh, '>', $tt_file or die "Cannot write template: $!";
    print $fh "[% FOREACH item IN objects %][% item.product %]\n[% END %]";
    close $fh;
}

sub make_dumper {
    my ( $out_file, %filter_opts ) = @_;
    my $fh = IO::File->new( $out_file, '>' ) or die "Cannot open $out_file: $!";
    return BeerFestDB::Dumper::Template->new(
        database   => schema(),
        template   => $tt_file,
        dump_class => 'cask',
        filehandle => $fh,
        %filter_opts,
    );
}

sub run_dump {
    my (%filter_opts) = @_;
    my ( undef, $out_file ) = tempfile( SUFFIX => '.out', UNLINK => 1 );
    my $dumper = make_dumper( $out_file, %filter_opts );
    my $fh = $dumper->filehandle;
    $dumper->dump();
    $fh->close;
    open my $rfh, '<', $out_file or die "Cannot read $out_file: $!";
    return do { local $/; <$rfh> };
}

# ---------------------------------------------------------------------------
# Unit tests: is_user_filtered
# ---------------------------------------------------------------------------

subtest 'is_user_filtered' => sub {
    my $d = BeerFestDB::Dumper::Template->new(
        database => schema(),
        template => $tt_file,
        filters  => [ [ 'category', 'ale' ], [ 'brewery', 'ACME' ] ],
    );

    my $obj_cat   = { category => 'ale',   product => 'Bitter'  };
    my $obj_brew  = { brewery  => 'ACME',  product => 'Lager'   };
    my $obj_none  = { category => 'cider', brewery => 'Other',
                      product  => 'Scrumpy' };

    ok(  $d->is_user_filtered($obj_cat),  'is_user_filtered: true when category matches'  );
    ok(  $d->is_user_filtered($obj_brew), 'is_user_filtered: true when brewery matches'   );
    ok( !$d->is_user_filtered($obj_none), 'is_user_filtered: false when nothing matches'  );

    # The count slot [2] of the matching filter tuple is incremented.
    my $filter = $d->filters->[0];   # [ 'category', 'ale', ... ]
    $d->is_user_filtered($obj_cat);  # increment count
    ok( ($filter->[2] // 0) > 0, 'is_user_filtered: matching increments filter count' );
};

# ---------------------------------------------------------------------------
# Unit tests: is_user_included
# ---------------------------------------------------------------------------

subtest 'is_user_included' => sub {
    my $d = BeerFestDB::Dumper::Template->new(
        database        => schema(),
        template        => $tt_file,
        include_filters => [ [ 'category', 'ale' ], [ 'brewery', 'TestBrewer' ] ],
    );

    my $obj_cat   = { category => 'ale',         product => 'Bitter'   };
    my $obj_brew  = { brewery  => 'TestBrewer',   product => 'TestBeer' };
    my $obj_none  = { category => 'cider',  brewery => 'Other',
                      product  => 'Scrumpy' };

    ok(  $d->is_user_included($obj_cat),  'is_user_included: true when category matches'  );
    ok(  $d->is_user_included($obj_brew), 'is_user_included: true when brewery matches'   );
    ok( !$d->is_user_included($obj_none), 'is_user_included: false when nothing matches'  );

    # The count slot [2] of the matching include_filter tuple is incremented.
    my $filter = $d->include_filters->[0];  # [ 'category', 'ale', ... ]
    $d->is_user_included($obj_cat);         # increment count
    ok( ($filter->[2] // 0) > 0, 'is_user_included: matching increments filter count' );
};

# ---------------------------------------------------------------------------
# Integration tests: dump() filter priority
#
# The test DB has exactly one cask: TestBeer (brewery=TestBrewer,
# category=Foreign beer).  The five subtests cover every branch of the
# $keep closure in BeerFestDB::Dumper::Template::dump().
# ---------------------------------------------------------------------------

subtest 'dump(): no filters — item included' => sub {
    my $output = run_dump();
    like( $output, qr/TestBeer/,
          'no filters: TestBeer appears in output' );
};

subtest 'dump(): matching exclude filter — item excluded' => sub {
    my $output = run_dump(
        filters => [ [ 'brewery', 'TestBrewer' ] ],
    );
    unlike( $output, qr/TestBeer/,
            'exclude match: TestBeer absent from output' );
};

subtest 'dump(): matching include filter — item included' => sub {
    my $output = run_dump(
        include_filters => [ [ 'brewery', 'TestBrewer' ] ],
    );
    like( $output, qr/TestBeer/,
          'include match: TestBeer present in output' );
};

subtest 'dump(): include and exclude both match — include has priority' => sub {
    my $output = run_dump(
        include_filters => [ [ 'brewery', 'TestBrewer' ] ],
        filters         => [ [ 'brewery', 'TestBrewer' ] ],
    );
    like( $output, qr/TestBeer/,
          'include wins over exclude: TestBeer still present in output' );
};

subtest 'dump(): include whitelist set but item not matched — item excluded' => sub {
    my $output = run_dump(
        include_filters => [ [ 'brewery', 'SomeOtherBrewery' ] ],
    );
    unlike( $output, qr/TestBeer/,
            'whitelist miss: TestBeer absent when include filter set but does not match' );
};

done_testing;
