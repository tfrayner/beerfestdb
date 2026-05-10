use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

BEGIN { use_ok 'BeerFestDB::Role::CsvParser' }

# Minimal consumer for testing the role in isolation.
{
    package TestCsvConsumer;
    use Moose;
    with 'BeerFestDB::Role::CsvParser';
}

# -----------------------------------------------------------------------
# parse_boolean
# -----------------------------------------------------------------------

my $dummy_file = (tempfile(SUFFIX => '.tsv', UNLINK => 1))[1];
my $c = TestCsvConsumer->new( csv_file => $dummy_file );

# True values
is( $c->parse_boolean('yes'),   1, 'parse_boolean: yes => true' );
is( $c->parse_boolean('y'),     1, 'parse_boolean: y => true' );
is( $c->parse_boolean('true'),  1, 'parse_boolean: true => true' );
is( $c->parse_boolean('1'),     1, 'parse_boolean: 1 => true' );
is( $c->parse_boolean('t'),     1, 'parse_boolean: t => true' );

# False values
is( $c->parse_boolean('no'),    0, 'parse_boolean: no => false' );
is( $c->parse_boolean('n'),     0, 'parse_boolean: n => false' );
is( $c->parse_boolean('false'), 0, 'parse_boolean: false => false' );
is( $c->parse_boolean('0'),     0, 'parse_boolean: 0 => false' );
is( $c->parse_boolean('f'),     0, 'parse_boolean: f => false' );

# Undefined / blank / n/a values
is( $c->parse_boolean(undef),   undef, 'parse_boolean: undef => undef' );
is( $c->parse_boolean(q{}),     undef, 'parse_boolean: empty string => undef' );
is( $c->parse_boolean('n/a'),   undef, 'parse_boolean: n/a => undef' );
is( $c->parse_boolean('N/A'),   undef, 'parse_boolean: N/A => undef' );
is( $c->parse_boolean('nd'),    undef, 'parse_boolean: nd => undef' );

# Invalid value should die
dies_ok { $c->parse_boolean('maybe') } 'parse_boolean: unrecognised value dies';

# -----------------------------------------------------------------------
# get_headers, getline, confirm_eof
# -----------------------------------------------------------------------

# Write a small tab-separated test file with a comment, blank line, then headers + data.
my ( $fh_tmp, $tmpfile ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
print $fh_tmp "# This is a comment\n";
print $fh_tmp "\n";
print $fh_tmp "name\tregion\tactive\n";
print $fh_tmp "Acme Brewery\tCambridgeshire\tyes\n";
close $fh_tmp;

my $p = TestCsvConsumer->new( csv_file => $tmpfile );

my $headers = $p->get_headers();
is_deeply( $headers, [ 'name', 'region', 'active' ],
           'get_headers: skips comments and returns column names' );

my $row = $p->getline();
is_deeply( $row, [ 'Acme Brewery', 'Cambridgeshire', 'yes' ],
           'getline: reads next data row correctly' );

# After reading all rows getline returns undef; confirm_eof should pass.
$p->getline();    # consume any trailing content
ok( $p->confirm_eof(), 'confirm_eof: returns true at end of file' );

# -----------------------------------------------------------------------
# getline: missing-value stripping on data rows
# -----------------------------------------------------------------------

# Write a file whose data row contains every recognised missing-value token
# plus a blank field, and whose header row contains the same strings (to
# confirm they are preserved verbatim in header mode).
my @missing_tokens = ( 'NA', 'N/A', 'ND', 'N/D', 'NULL', 'TBC', 'TBD' );

my ( $fh_mv, $mv_file ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
# Header row: use the token names as column headers.
print $fh_mv join( "\t", @missing_tokens, 'blank', 'real_value' ) . "\n";
# Data row: one of each token, an empty field, and a real value.
print $fh_mv join( "\t", @missing_tokens, '', 'beer' ) . "\n";
# Data row: check case-insensitivity, surrounding whitespace, and whitespace-only fields.
print $fh_mv "na\t n/a \t Nd \t N/d \t null \t tbc \t tbd \t   \t beer \n";
close $fh_mv;

my $mv = TestCsvConsumer->new( csv_file => $mv_file );

# Header row must be returned unchanged.
my $mv_headers = $mv->get_headers();
is_deeply( $mv_headers,
           [ @missing_tokens, 'blank', 'real_value' ],
           'getline (header): missing-value tokens in header row are preserved' );

# Data row: all missing-value tokens and the blank field become empty strings.
my $mv_row = $mv->getline();
is_deeply( $mv_row,
           [ ('') x (scalar(@missing_tokens) + 1), 'beer' ],
           'getline (data): recognised missing-value tokens replaced with empty string' );

# Data row: case-insensitive and whitespace-tolerant.
my $mv_row2 = $mv->getline();
is_deeply( $mv_row2,
           [ ('') x (scalar(@missing_tokens) + 1), ' beer ' ],
           'getline (data): missing-value replacement is case-insensitive and preserves whitespace' );

# -----------------------------------------------------------------------
# getline: comment lines in the data section are skipped
# -----------------------------------------------------------------------

# Write a file where comment lines appear between data rows, including
# a comment with leading whitespace to exercise the \s* part of the regex.
my ( $fh_cmt, $cmt_file ) = tempfile( SUFFIX => '.tsv', UNLINK => 1 );
print $fh_cmt "name\tvalue\n";
print $fh_cmt "row_one\t1\n";
print $fh_cmt "# full-line comment between data rows\n";
print $fh_cmt "  # comment with leading whitespace\n";
print $fh_cmt "row_two\t2\n";
close $fh_cmt;

my $cmt = TestCsvConsumer->new( csv_file => $cmt_file );
$cmt->get_headers();   # consume the header line

my $cmt_row1 = $cmt->getline();
is_deeply( $cmt_row1, [ 'row_one', '1' ],
           'getline: returns first data row before inline comments' );

my $cmt_row2 = $cmt->getline();
is_deeply( $cmt_row2, [ 'row_two', '2' ],
           'getline: skips comment lines between data rows' );

my $cmt_eof = $cmt->getline();
is( $cmt_eof, undef, 'getline: returns undef after last data row' );

done_testing();
