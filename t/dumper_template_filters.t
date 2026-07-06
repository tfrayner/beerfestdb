use strict;
use warnings;

use utf8;
use open( ':std', ':encoding(UTF-8)' );

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

# ---------------------------------------------------------------------------
# Unit tests: filter_to_latex()
#
# Tests for all character substitutions supported by the filter_to_latex
# function, covering common LaTeX control characters, accented characters,
# and special characters used in brewery names and product descriptions.
# ---------------------------------------------------------------------------

my @filter_to_latex_tests = (
    {
        name  => 'filter_to_latex: common LaTeX control characters',
        cases => [
            [ '{test}',          '\\{test\\}',                                    'filter_to_latex: { and } are escaped to \\{ and \\}' ],
            [ 'A & B',           'A \\& B',                                       'filter_to_latex: & is escaped to \\&' ],
            [ '50% discount',    '50\\% discount',                                'filter_to_latex: % is escaped to \\%' ],
            [ '#1 Beer',         '\\#1 Beer',                                     'filter_to_latex: # is escaped to \\#' ],
            [ 'test_value',      'test\\_value',                                  'filter_to_latex: _ is escaped to \\_' ],
            [ 'Price: $5',       'Price: \\$5',                                   'filter_to_latex: $ is escaped to \\$' ],
            [ "line1\nline2",    'line1\\\\line2',                                 'filter_to_latex: newline is escaped to \\\\' ],
            [ "It's good",       'It{\\textquotesingle}s good',                   'filter_to_latex: single quote is converted to {\\textquotesingle}' ],
            [ 'He said "Hello"', 'He said {\\textquotedbl}Hello{\\textquotedbl}', 'filter_to_latex: double quote is converted to {\\textquotedbl}' ],
        ],
    },
    {
        name  => 'filter_to_latex: grave accents (Latin-1)',
        cases => [
            [ 'à', '{\`a}', 'filter_to_latex: à (grave a) is converted' ],
            [ 'è', '{\`e}', 'filter_to_latex: è (grave e) is converted' ],
            [ 'ì', '{\`i}', 'filter_to_latex: ì (grave i) is converted' ],
            [ 'ò', '{\`o}', 'filter_to_latex: ò (grave o) is converted' ],
            [ 'ù', '{\`u}', 'filter_to_latex: ù (grave u) is converted' ],
            [ 'à à', '{\`a} {\`a}', 'filter_to_latex: à (grave a) is converted (multiple)' ],
        ],
    },
    {
        name  => 'filter_to_latex: grave accents (UTF-8)',
        cases => [
            [ "\x{e0}", '{\`a}', 'filter_to_latex: UTF-8 à (grave a) is converted' ],
            [ "\x{e8}", '{\`e}', 'filter_to_latex: UTF-8 è (grave e) is converted' ],
            [ "\x{ec}", '{\`i}', 'filter_to_latex: UTF-8 ì (grave i) is converted' ],
            [ "\x{f2}", '{\`o}', 'filter_to_latex: UTF-8 ò (grave o) is converted' ],
            [ "\x{f9}", '{\`u}', 'filter_to_latex: UTF-8 ù (grave u) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: acute accents (Latin-1, lowercase)',
        cases => [
            [ 'á', "{\\'a}", 'filter_to_latex: á (acute a) is converted' ],
            [ 'é', "{\\'e}", 'filter_to_latex: é (acute e) is converted' ],
            [ 'í', "{\\'i}", 'filter_to_latex: í (acute i) is converted' ],
            [ 'ó', "{\\'o}", 'filter_to_latex: ó (acute o) is converted' ],
            [ 'ú', "{\\'u}", 'filter_to_latex: ú (acute u) is converted' ],
            [ 'ý', "{\\'y}", 'filter_to_latex: ý (acute y) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: acute accents (Latin-1, uppercase)',
        cases => [
            [ 'Á', "{\\'A}", 'filter_to_latex: Á (acute A) is converted' ],
            [ 'É', "{\\'E}", 'filter_to_latex: É (acute E) is converted' ],
            [ 'Í', "{\\'I}", 'filter_to_latex: Í (acute I) is converted' ],
            [ 'Ó', "{\\'O}", 'filter_to_latex: Ó (acute O) is converted' ],
            [ 'Ú', "{\\'U}", 'filter_to_latex: Ú (acute U) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: acute accents (UTF-8, lowercase)',
        cases => [
            [ "\x{e1}", "{\\'a}", 'filter_to_latex: UTF-8 á (acute a) is converted' ],
            [ "\x{e9}", "{\\'e}", 'filter_to_latex: UTF-8 é (acute e) is converted' ],
            [ "\x{ed}", "{\\'i}", 'filter_to_latex: UTF-8 í (acute i) is converted' ],
            [ "\x{f3}", "{\\'o}", 'filter_to_latex: UTF-8 ó (acute o) is converted' ],
            [ "\x{fa}", "{\\'u}", 'filter_to_latex: UTF-8 ú (acute u) is converted' ],
            [ "\x{fd}", "{\\'y}", 'filter_to_latex: UTF-8 ý (acute y) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: acute accents (UTF-8, uppercase)',
        cases => [
            [ "\x{c1}", "{\\'A}", 'filter_to_latex: UTF-8 Á (acute A) is converted' ],
            [ "\x{c9}", "{\\'E}", 'filter_to_latex: UTF-8 É (acute E) is converted' ],
            [ "\x{cd}", "{\\'I}", 'filter_to_latex: UTF-8 Í (acute I) is converted' ],
            [ "\x{d3}", "{\\'O}", 'filter_to_latex: UTF-8 Ó (acute O) is converted' ],
            [ "\x{da}", "{\\'U}", 'filter_to_latex: UTF-8 Ú (acute U) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: circumflex accents (Latin-1)',
        cases => [
            [ 'â', '{\^a}', 'filter_to_latex: â (circumflex a) is converted' ],
            [ 'ê', '{\^e}', 'filter_to_latex: ê (circumflex e) is converted' ],
            [ 'î', '{\^i}', 'filter_to_latex: î (circumflex i) is converted' ],
            [ 'ô', '{\^o}', 'filter_to_latex: ô (circumflex o) is converted' ],
            [ 'û', '{\^u}', 'filter_to_latex: û (circumflex u) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: circumflex accents (UTF-8)',
        cases => [
            [ "\x{e2}", '{\^a}', 'filter_to_latex: UTF-8 â (circumflex a) is converted' ],
            [ "\x{ea}", '{\^e}', 'filter_to_latex: UTF-8 ê (circumflex e) is converted' ],
            [ "\x{ee}", '{\^i}', 'filter_to_latex: UTF-8 î (circumflex i) is converted' ],
            [ "\x{f4}", '{\^o}', 'filter_to_latex: UTF-8 ô (circumflex o) is converted' ],
            [ "\x{fb}", '{\^u}', 'filter_to_latex: UTF-8 û (circumflex u) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: umlauts (Latin-1, lowercase)',
        cases => [
            [ 'ä', '{\\"a}', 'filter_to_latex: ä (umlaut a) is converted' ],
            [ 'ë', '{\\"e}', 'filter_to_latex: ë (umlaut e) is converted' ],
            [ 'ï', '{\\"i}', 'filter_to_latex: ï (umlaut i) is converted' ],
            [ 'ö', '{\\"o}', 'filter_to_latex: ö (umlaut o) is converted' ],
            [ 'ü', '{\\"u}', 'filter_to_latex: ü (umlaut u) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: umlauts (Latin-1, uppercase)',
        cases => [
            [ 'Ä', '{\\"A}', 'filter_to_latex: Ä (umlaut A) is converted' ],
            [ 'Ë', '{\\"E}', 'filter_to_latex: Ë (umlaut E) is converted' ],
            [ 'Ï', '{\\"I}', 'filter_to_latex: Ï (umlaut I) is converted' ],
            [ 'Ö', '{\\"O}', 'filter_to_latex: Ö (umlaut O) is converted' ],
            [ 'Ü', '{\\"U}', 'filter_to_latex: Ü (umlaut U) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: umlauts (UTF-8, lowercase)',
        cases => [
            [ "\x{e4}", '{\\"a}', 'filter_to_latex: UTF-8 ä (umlaut a) is converted' ],
            [ "\x{eb}", '{\\"e}', 'filter_to_latex: UTF-8 ë (umlaut e) is converted' ],
            [ "\x{ef}", '{\\"i}', 'filter_to_latex: UTF-8 ï (umlaut i) is converted' ],
            [ "\x{f6}", '{\\"o}', 'filter_to_latex: UTF-8 ö (umlaut o) is converted' ],
            [ "\x{fc}", '{\\"u}', 'filter_to_latex: UTF-8 ü (umlaut u) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: umlauts (UTF-8, uppercase)',
        cases => [
            [ "\x{c4}", '{\\"A}', 'filter_to_latex: UTF-8 Ä (umlaut A) is converted' ],
            [ "\x{cb}", '{\\"E}', 'filter_to_latex: UTF-8 Ë (umlaut E) is converted' ],
            [ "\x{cf}", '{\\"I}', 'filter_to_latex: UTF-8 Ï (umlaut I) is converted' ],
            [ "\x{d6}", '{\\"O}', 'filter_to_latex: UTF-8 Ö (umlaut O) is converted' ],
            [ "\x{dc}", '{\\"U}', 'filter_to_latex: UTF-8 Ü (umlaut U) is converted' ],
        ],
    },
    {
        name  => 'filter_to_latex: miscellaneous characters (Latin-1)',
        cases => [
            [ '£', '{\\textsterling}', 'filter_to_latex: £ (pound sign) is converted'    ],
            [ 'ç', '\\c{c}',           'filter_to_latex: ç (c cedilla) is converted'      ],
            [ 'ß', '{\\ss}',           'filter_to_latex: ß (German sharp s) is converted' ],
            [ 'ø', '{\\o}',            'filter_to_latex: ø (o slash) is converted'        ],
        ],
    },
    {
        name  => 'filter_to_latex: miscellaneous characters (UTF-8)',
        cases => [
            [ "\x{a3}", '{\\textsterling}', 'filter_to_latex: UTF-8 £ (pound sign) is converted'    ],
            [ "\x{e7}", '\\c{c}',           'filter_to_latex: UTF-8 ç (c cedilla) is converted'      ],
            [ "\x{df}", '{\\ss}',           'filter_to_latex: UTF-8 ß (German sharp s) is converted' ],
            [ "\x{f8}", '{\\o}',            'filter_to_latex: UTF-8 ø (o slash) is converted'        ],
        ],
    },
    {
        name  => 'filter_to_latex: mathematical and special symbols (UTF-8)',
        cases => [
            [ 'π', '\\ensuremath{\\pi}',    'filter_to_latex: π (pi) is converted to \\ensuremath(\\pi}' ],
            [ '°', '{\\textdegree}',         'filter_to_latex: ° (degree) is converted'       ],
            [ '·', '{\\textperiodcentered}', 'filter_to_latex: · (middle dot) is converted'   ],
        ],
    },
    {
        name  => 'filter_to_latex: mathematical and special symbols (UTF-8 codes)',
        cases => [
            [ "\x{3c0}", '\\ensuremath{\\pi}',    'filter_to_latex: UTF-8 π (pi) is converted to \\ensuremath(\\pi}' ],
            [ "\x{b0}",  '{\\textdegree}',         'filter_to_latex: UTF-8 ° (degree) is converted'       ],
            [ "\x{b7}",  '{\\textperiodcentered}', 'filter_to_latex: UTF-8 · (middle dot) is converted'   ],
        ],
    },
    {
        name  => 'filter_to_latex: eastern European characters (UTF-8)',
        cases => [
            [ 'ž', '\v{z}', 'filter_to_latex: ž (z caron) is converted' ],
            [ 'Ā', '\={A}', 'filter_to_latex: Ā (A macron) is converted' ],
            [ 'ě', '\v{e}', 'filter_to_latex: ě (e caron) is converted'  ],
        ],
    },
    {
        name  => 'filter_to_latex: eastern European characters (UTF-8 codes)',
        cases => [
            [ "\x{17e}", '\\v{z}', 'filter_to_latex: UTF-8 ž (z caron) is converted' ],
            [ "\x{100}", '\\={A}', 'filter_to_latex: UTF-8 Ā (A macron) is converted' ],
            [ "\x{11b}", '\\v{e}', 'filter_to_latex: UTF-8 ě (e caron) is converted'  ],
        ],
    },
);

for my $test ( @filter_to_latex_tests ) {
    subtest $test->{name} => sub {
        for my $case ( @{ $test->{cases} } ) {
            is( BeerFestDB::Dumper::Template::filter_to_latex( $case->[0] ),
                $case->[1], $case->[2] );
        }
    };
}

done_testing;
