use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Role::DipMunger' }

# Minimal Moose consumer of the DipMunger role.
{
    package TestDipMunger;
    use Moose;
    with 'BeerFestDB::Role::DipMunger';
    no Moose;
}

my $s      = schema();
my $munger = TestDipMunger->new();

# ── Additional fixtures for gap-filling tests (idempotent) ──────────────────

# Batch 2 has no cask measurements (a "gap" in the dip record).
$s->resultset('MeasurementBatch')->find_or_create({
    measurement_batch_id => 2,
    festival_id          => 1,
    measurement_time     => '1970-01-02 01:00:00',
});

# Batch 3 has a cask measurement (2.0 litres).
$s->resultset('MeasurementBatch')->find_or_create({
    measurement_batch_id => 3,
    festival_id          => 1,
    measurement_time     => '1970-01-03 01:00:00',
});

$s->resultset('CaskMeasurement')->find_or_create({
    cask_measurement_id  => 2,
    cask_id              => 1,
    container_measure_id => 1,   # litre (litre_multiplier = 1.0)
    measurement_batch_id => 3,
    volume               => 2.0,
});

# A festival with no measurement batches, for the undef-return test.
my $empty_festival = $s->resultset('Festival')->find_or_create({
    festival_id => 2,
    year        => 2021,
    name        => 'EmptyFestival',
});

my $festival = $s->resultset('Festival')->find(1);
my $cask     = $s->resultset('Cask')->find(1);

# ── _latest_dipbatch_with_data ───────────────────────────────────────────────

my $latest_id = $munger->_latest_dipbatch_with_data($festival);
is( $latest_id, 3,
    '_latest_dipbatch_with_data returns id of most recent batch that has data' );

is( $munger->_latest_dipbatch_with_data($empty_festival), undef,
    '_latest_dipbatch_with_data returns undef when festival has no batches' );

# ── munge_dips ───────────────────────────────────────────────────────────────

my $dips = $munger->munge_dips($cask);

is( ref $dips, 'HASH', 'munge_dips returns a hashref' );
is( scalar keys %$dips, 3,
    'munge_dips returns one entry per batch up to and including latest with data' );

# default_measurement_unit defaults to 'gallon' (litre_multiplier = 4.54609188).
# Conversion: vol_gallons = vol_litres * (litre_multiplier_of_measure / gallon_litre_multiplier)
my $gallon = 4.54609188;

# Batch 1: CaskMeasurement volume=3.0 L with container_measure litre (multiplier=1.0).
ok( exists $dips->{1}, 'munge_dips has an entry for batch 1' );
ok( abs( $dips->{1} - ( 3.0 / $gallon ) ) < 1e-6,
    'munge_dips batch-1 volume is 3 litres expressed in gallons' );

# Batch 2 has no measurement; the previous volume should be carried forward.
ok( exists $dips->{2}, 'munge_dips has an entry for batch 2 (gap batch)' );
ok( abs( $dips->{2} - $dips->{1} ) < 1e-9,
    'munge_dips gap-fills batch 2 with the volume from batch 1' );

# Batch 3: CaskMeasurement volume=2.0 L.
ok( exists $dips->{3}, 'munge_dips has an entry for batch 3' );
ok( abs( $dips->{3} - ( 2.0 / $gallon ) ) < 1e-6,
    'munge_dips batch-3 volume is 2 litres expressed in gallons' );

# Batch-3 volume must be less than batch-1 volume (cask is being consumed).
ok( $dips->{3} < $dips->{1},
    'munge_dips batch-3 volume is lower than batch-1 volume' );

done_testing();
