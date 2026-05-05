use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Role::MenuSelector' }

# Minimal Moose consumer: provides the required 'database' attribute.
# NB: 'has' must come before 'with' so the 'requires' check passes at
# role-composition time.
{
    package TestMenuSelector;
    use Moose;
    has 'database' => ( is => 'ro', required => 1 );
    with 'BeerFestDB::Role::MenuSelector';
    no Moose;
}

my $s = schema();

# ── festival() — non-interactive path via current_festival config ────────────

my $obj = TestMenuSelector->new( database => $s );

my $fest = $obj->festival();
isa_ok( $fest, 'BeerFestDB::ORM::Festival',
        'festival() returns a Festival ORM object' );
is( $fest->name, 'TestFestival',
    'festival() returns the festival named in current_festival config' );

# Second call returns the same cached object (same database id).
my $fest2 = $obj->festival();
is( $fest2->festival_id, $fest->festival_id,
    'festival() returns the same cached object on repeated calls' );

# Explicit setter: festival($obj) updates the cache.
my $alt = TestMenuSelector->new( database => $s );
my $fest_obj = $s->resultset('Festival')->find(1);
$alt->festival($fest_obj);
is( $alt->festival->festival_id, $fest_obj->festival_id,
    'festival($obj) stores and returns the supplied festival' );

# ── select_festival() — mock STDIN ───────────────────────────────────────────

{
    local *STDIN;
    open( STDIN, '<', \"1\n" ) or die "Cannot reopen STDIN: $!";
    my $sel = TestMenuSelector->new( database => $s )->select_festival();
    isa_ok( $sel, 'BeerFestDB::ORM::Festival',
            'select_festival() returns a Festival object' );
    ok( defined $sel->name, 'select_festival() result has a defined name' );
}

# ── select_order_batch() — mock STDIN ────────────────────────────────────────

# Reset to a fresh consumer with TestFestival pre-cached so the method
# does not need to prompt for a festival interactively.
{
    my $fresh = TestMenuSelector->new( database => $s );
    $fresh->_festival( $s->resultset('Festival')->find(1) );

    local *STDIN;
    open( STDIN, '<', \"1\n" ) or die "Cannot reopen STDIN: $!";
    my $batch = $fresh->select_order_batch();
    isa_ok( $batch, 'BeerFestDB::ORM::OrderBatch',
            'select_order_batch() returns an OrderBatch object' );
    is( $batch->description, 'TestOrderBatch',
        'select_order_batch() returns the expected order batch' );
}

# ── select_dip_batch() — mock STDIN ──────────────────────────────────────────

{
    my $fresh = TestMenuSelector->new( database => $s );
    $fresh->_festival( $s->resultset('Festival')->find(1) );

    local *STDIN;
    open( STDIN, '<', \"1\n" ) or die "Cannot reopen STDIN: $!";
    my $batch = $fresh->select_dip_batch();
    isa_ok( $batch, 'BeerFestDB::ORM::MeasurementBatch',
            'select_dip_batch() returns a MeasurementBatch object' );
    is( $batch->measurement_time, '1970-01-01 01:00:00',
        'select_dip_batch() returns the expected measurement batch' );
}

done_testing();
