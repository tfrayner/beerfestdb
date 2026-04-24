use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::StillagePlanner' }
BEGIN { use_ok 'BeerFestDB::StillagePlanner::CaskEntry' }

my $s = schema();

# ── Extra fixtures ────────────────────────────────────────────────────────────
#
# The pristine TestFestivalDB provides:
#   Festival 1, Company 1 (TestBrewer), Product 1 (TestBeer),
#   FestivalProduct 1, Gyle 1, StillageLocation 1 (TestStillage),
#   CaskManagement 1 (firkin, cellar_ref=1), Cask 1.
#
# We add a second stillage, two more beers with several casks each,
# and one SOR cask to exercise all scoring paths.

# Second stillage on the same festival
my $sl2 = $s->resultset('StillageLocation')->find_or_create({
    stillage_location_id => 2,
    festival_id          => 1,
    description          => 'PlannerTestStillage',
});

# Second company / product / fp / gyle for "AardvarkBrew Amber"
my $co2 = $s->resultset('Company')->find_or_create({
    company_id        => 2,
    company_region_id => 5,
    name              => 'AardvarkBrew',
});

my $prod2 = $s->resultset('Product')->find_or_create({
    product_id          => 2,
    company_id          => 2,
    product_category_id => 1,
    name                => 'Amber',
});

my $fp2 = $s->resultset('FestivalProduct')->find_or_create({
    festival_product_id => 2,
    product_id          => 2,
    festival_id         => 1,
    sale_volume_id      => 1,
    sale_currency_id    => 1,
});

my $gyle2 = $s->resultset('Gyle')->find_or_create({
    gyle_id             => 2,
    company_id          => 2,
    festival_product_id => 2,
    internal_reference  => 2,
});

# Third company / product / fp / gyle for "ZymurgyCo Zest"
my $co3 = $s->resultset('Company')->find_or_create({
    company_id        => 3,
    company_region_id => 5,
    name              => 'ZymurgyCo',
});

my $prod3 = $s->resultset('Product')->find_or_create({
    product_id          => 3,
    company_id          => 3,
    product_category_id => 1,
    name                => 'Zest',
});

my $fp3 = $s->resultset('FestivalProduct')->find_or_create({
    festival_product_id => 3,
    product_id          => 3,
    festival_id         => 1,
    sale_volume_id      => 1,
    sale_currency_id    => 1,
});

my $gyle3 = $s->resultset('Gyle')->find_or_create({
    gyle_id             => 3,
    company_id          => 3,
    festival_product_id => 3,
    internal_reference  => 3,
});

# CaskManagement rows assigned to sl2
# AardvarkBrew Amber: 3 casks (firkin, cellar refs 10-12)
for my $ref ( 10, 11, 12 ) {
    my $cm = $s->resultset('CaskManagement')->find_or_create({
        festival_id          => 1,
        container_size_id    => 1,    # firkin
        currency_id          => 1,
        stillage_location_id => 2,
        cellar_reference     => $ref,
        is_sale_or_return    => 0,
    });
    $s->resultset('Cask')->find_or_create({
        gyle_id            => 2,
        cask_management_id => $cm->cask_management_id,
        is_condemned       => 0,
    });
}

# ZymurgyCo Zest: 2 casks (firkin, cellar refs 20-21); cask 21 is SOR
for my $ref ( 20, 21 ) {
    my $cm = $s->resultset('CaskManagement')->find_or_create({
        festival_id          => 1,
        container_size_id    => 1,
        currency_id          => 1,
        stillage_location_id => 2,
        cellar_reference     => $ref,
        is_sale_or_return    => ( $ref == 21 ? 1 : 0 ),
    });
    $s->resultset('Cask')->find_or_create({
        gyle_id            => 3,
        cask_management_id => $cm->cask_management_id,
        is_condemned       => 0,
    });
}

# ── Helper: build a planner for sl2 ──────────────────────────────────────────

sub make_planner {
    my (%args) = @_;
    return BeerFestDB::StillagePlanner->new(
        database          => $s,
        stillage_location => $sl2,
        num_bays          => $args{num_bays}    // 5,
        bay_capacity      => $args{bay_capacity} // 1,
        max_iterations    => $args{max_iterations} // 200,
        convergence_streak => $args{convergence_streak} // 50,
    );
}

# ── Tests: CaskEntry ──────────────────────────────────────────────────────────

subtest 'CaskEntry basics' => sub {
    my $cm = $s->resultset('CaskManagement')->find({ cellar_reference => 10,
                                                     festival_id => 1 });
    my $entry = BeerFestDB::StillagePlanner::CaskEntry->new(
        cask_management     => $cm,
        beer_name           => 'Amber',
        brewery_name        => 'AardvarkBrew',
        sort_key            => 'aardvarkbrew amber',
        cask_number         => 1,
        cask_count          => 3,
        is_sale_or_return   => 0,
        container_type      => 'firkin',
        festival_product_id => 2,
    );

    is( $entry->beer_name,    'Amber',            'beer_name set' );
    is( $entry->brewery_name, 'AardvarkBrew',     'brewery_name set' );
    is( $entry->sort_key,     'aardvarkbrew amber', 'sort_key set' );
    is( $entry->cask_number,  1,                  'cask_number set' );
    is( $entry->cask_count,   3,                  'cask_count set' );
    ok( !$entry->is_sale_or_return,               'SOR false' );

    like( $entry->label, qr/Amber/, 'label contains beer name' );
    like( $entry->label, qr/firkin/, 'label contains container type' );
    like( $entry->label, qr/1\/3/,   'label contains cask_number/cask_count' );
};

# ── Tests: StillagePlanner construction ──────────────────────────────────────

subtest 'constructor and num_positions' => sub {
    my $p = make_planner( num_bays => 4, bay_capacity => 2 );
    isa_ok( $p, 'BeerFestDB::StillagePlanner' );
    is( $p->num_positions, 8, 'num_positions = num_bays * bay_capacity' );
};

# ── Tests: load_casks ────────────────────────────────────────────────────────

subtest 'load_casks' => sub {
    my $p = make_planner();
    my $n = $p->load_casks();

    is( $n, 5, 'load_casks returns 5 entries (3 Amber + 2 Zest)' );

    my @entries = @{ $p->_cask_entries };
    is( scalar @entries, 5, '_cask_entries has 5 items' );

    # Verify cask numbering within each beer
    my @amber = sort { $a->cask_number <=> $b->cask_number }
                grep { $_->beer_name eq 'Amber' } @entries;
    is( scalar @amber, 3,    '3 Amber entries' );
    is( $amber[0]->cask_number, 1, 'Amber cask 1 number' );
    is( $amber[0]->cask_count,  3, 'Amber cask 1 count' );
    is( $amber[2]->cask_number, 3, 'Amber cask 3 number' );

    my @zest = sort { $a->cask_number <=> $b->cask_number }
               grep { $_->beer_name eq 'Zest' } @entries;
    is( scalar @zest, 2,    '2 Zest entries' );
    is( $zest[0]->cask_number, 1, 'Zest cask 1 number' );
    is( $zest[1]->cask_number, 2, 'Zest cask 2 number' );
    ok( !$zest[0]->is_sale_or_return, 'Zest cask 1 is not SOR' );
    ok(  $zest[1]->is_sale_or_return, 'Zest cask 2 (ref 21) is SOR' );
};

# ── Tests: initialise ────────────────────────────────────────────────────────

subtest 'initialise sorts alphabetically' => sub {
    my $p = make_planner( num_bays => 5, bay_capacity => 1 );
    $p->load_casks();
    $p->initialise();

    my $layout = $p->_layout;
    is( scalar @$layout, 5, 'layout has 5 slots (= num_positions, no deck)' );

    # AardvarkBrew Amber sorts before ZymurgyCo Zest
    is( $layout->[0]->brewery_name, 'AardvarkBrew',
        'first slot is AardvarkBrew' );
    is( $layout->[3]->brewery_name, 'ZymurgyCo',
        'fourth slot is ZymurgyCo' );
};

subtest 'initialise creates deck when more casks than slots' => sub {
    my $p = make_planner( num_bays => 3, bay_capacity => 1 ); # 3 slots, 5 casks
    $p->load_casks();
    $p->initialise();

    my $layout = $p->_layout;
    is( scalar @$layout, 5, 'layout has 5 entries total (3 on-stillage + 2 deck)' );
    is( $p->num_positions, 3, 'num_positions is 3' );
};

# ── Tests: score ─────────────────────────────────────────────────────────────

subtest 'score: alphabetical ordering' => sub {
    # Build a planner with 2 slots, manually construct a layout to test scoring
    my $p = make_planner( num_bays => 2, bay_capacity => 1 );
    $p->load_casks();

    my @entries = @{ $p->_cask_entries };
    my ($amber) = grep { $_->beer_name eq 'Amber' && $_->cask_number == 1 } @entries;
    my ($zest)  = grep { $_->beer_name eq 'Zest'  && $_->cask_number == 1 } @entries;

    # Correct order: Amber before Zest (no penalty)
    $p->_layout( [ $amber, $zest ] );
    my $good_score = $p->score;

    # Reversed: Zest before Amber (alphabetical violation)
    $p->_layout( [ $zest, $amber ] );
    my $bad_score = $p->score;

    cmp_ok( $bad_score, '>', $good_score,
        'reversed order has higher score than sorted order' );
    cmp_ok( $bad_score - $good_score, '>=', $p->weight_alphabetical,
        'score difference is at least one alphabetical weight unit' );
};

subtest 'score: proximity penalty for separated same-beer casks' => sub {
    my $p = make_planner( num_bays => 4, bay_capacity => 1 );
    $p->load_casks();

    my @entries = @{ $p->_cask_entries };
    my @amber = sort { $a->cask_number <=> $b->cask_number }
                grep { $_->beer_name eq 'Amber' } @entries;

    # Layout: amber1, undef, amber2 → gap of 1 between casks
    $p->_layout( [ $amber[0], undef, $amber[1], undef ] );
    my $gap_score = $p->score;

    # Layout: amber1, amber2, undef, undef → adjacent, no gap
    $p->_layout( [ $amber[0], $amber[1], undef, undef ] );
    my $adj_score = $p->score;

    cmp_ok( $gap_score, '>', $adj_score,
        'separated same-beer casks score worse than adjacent' );
    is( $gap_score - $adj_score, $p->weight_proximity,
        'gap of 1 adds exactly one proximity weight unit' );
};

subtest 'score: deck penalty for overflow casks' => sub {
    my $p = make_planner( num_bays => 1, bay_capacity => 1 ); # 1 slot
    $p->load_casks();

    my @entries  = @{ $p->_cask_entries };
    my ($amber1) = grep { $_->beer_name eq 'Amber' && $_->cask_number == 1 } @entries;
    my ($amber3) = grep { $_->beer_name eq 'Amber' && $_->cask_number == 3 } @entries;

    # amber1 on stillage, amber3 on deck
    $p->_layout( [ $amber1, $amber3 ] );
    my $s1 = $p->score;

    # amber3 on stillage, amber1 on deck
    $p->_layout( [ $amber3, $amber1 ] );
    my $s2 = $p->score;

    cmp_ok( $s2, '>', $s1,
        'first cask on deck penalised more than third cask on deck' );
};

subtest 'score: SOR deck penalty is lower' => sub {
    my $p = make_planner( num_bays => 1, bay_capacity => 1 );
    $p->load_casks();

    my @entries  = @{ $p->_cask_entries };
    my ($zest1)  = grep { $_->beer_name eq 'Zest' && $_->cask_number == 1 } @entries;
    my ($zest2)  = grep { $_->beer_name eq 'Zest' && $_->cask_number == 2 } @entries;

    # zest2 (SOR) on deck
    $p->_layout( [ $zest1, $zest2 ] );
    my $sor_deck_score = $p->score;

    # zest1 (non-SOR) on deck
    $p->_layout( [ $zest2, $zest1 ] );
    my $non_sor_deck_score = $p->score;

    cmp_ok( $sor_deck_score, '<', $non_sor_deck_score,
        'SOR cask on deck has lower penalty than non-SOR cask on deck' );
};

# ── Tests: plan ──────────────────────────────────────────────────────────────

subtest 'plan improves or maintains score' => sub {
    my $p = make_planner( num_bays => 5, bay_capacity => 1,
                          max_iterations => 1000, convergence_streak => 100 );
    $p->load_casks();

    # Deliberately scramble the initial layout
    $p->initialise();
    my @scrambled = reverse @{ $p->_layout };
    $p->_layout( \@scrambled );

    my $before = $p->score;
    my $after  = $p->plan;

    cmp_ok( $after, '<=', $before,
        'plan() does not increase the score' );
};

subtest 'plan lives and returns a number' => sub {
    my $p = make_planner();
    $p->load_casks();
    $p->initialise();
    my $score;
    lives_ok { $score = $p->plan } 'plan() lives';
    ok( looks_like_number($score), 'plan() returns a number' );
};

subtest 'plan raises error if called before initialise' => sub {
    my $p = make_planner();
    $p->load_casks();
    # Do NOT call initialise()
    throws_ok { $p->plan } qr/initialise/i,
        'plan() croaks when layout is empty';
};

# ── Tests: render ────────────────────────────────────────────────────────────

subtest 'render returns a non-empty string containing slot info' => sub {
    my $p = make_planner( num_bays => 5, bay_capacity => 1 );
    $p->load_casks();
    $p->initialise();

    my $text = $p->render;
    ok( defined $text && length $text > 0, 'render returns non-empty string' );
    like( $text, qr/PlannerTestStillage/, 'render includes stillage name' );
    like( $text, qr/Score:/,             'render includes score' );
    like( $text, qr/Amber/,             'render includes beer name' );
    like( $text, qr/Bay/,               'render includes bay label' );
};

subtest 'render shows DECK section when there are overflow casks' => sub {
    my $p = make_planner( num_bays => 3, bay_capacity => 1 ); # 3 slots, 5 casks
    $p->load_casks();
    $p->initialise();

    my $text = $p->render;
    like( $text, qr/DECK/, 'render mentions DECK when casks overflow' );
};

# ── Tests: apply ─────────────────────────────────────────────────────────────

subtest 'apply writes stillage_bay and x_location to DB' => sub {
    my $p = make_planner( num_bays => 5, bay_capacity => 1 );
    $p->load_casks();
    $p->initialise();
    $p->plan;

    lives_ok { $p->apply } 'apply() lives';

    # Check that all entries have stillage_bay set (since 5 slots >= 5 casks)
    for my $entry ( @{ $p->_cask_entries } ) {
        my $cm = $entry->cask_management;
        $cm->discard_changes;   # refresh from DB
        ok( defined $cm->stillage_bay,
            "cask_management " . $cm->cask_management_id . " has stillage_bay set" );
        ok( defined $cm->stillage_x_location,
            "cask_management " . $cm->cask_management_id . " has x_location set" );
        is( $cm->cask_graveyard, undef,
            "cask_management " . $cm->cask_management_id . " not in graveyard" );
    }
};

subtest 'apply marks overflow casks as deck' => sub {
    my $p = make_planner( num_bays => 3, bay_capacity => 1 ); # 3 slots, 5 casks
    $p->load_casks();
    $p->initialise();

    lives_ok { $p->apply } 'apply() with deck overflow lives';

    my $layout  = $p->_layout;
    my $num_pos = $p->num_positions;

    for my $slot ( $num_pos .. $#$layout ) {
        my $entry = $layout->[$slot];
        next unless defined $entry;
        my $cm = $entry->cask_management;
        $cm->discard_changes;
        is( $cm->cask_graveyard, 'deck',
            "overflow slot $slot cask_graveyard = 'deck'" );
        is( $cm->stillage_bay, undef,
            "overflow slot $slot stillage_bay is undef" );
    }
};

# ── Test: score of alphabetically optimal layout is 0 (proximity only) ───────

subtest 'alphabetically sorted layout has no alphabetical penalty' => sub {
    my $p = make_planner( num_bays => 5, bay_capacity => 1 );
    $p->load_casks();
    $p->initialise();

    my $score = $p->score;

    # There should be no alphabetical penalty (entries are sorted on initialise)
    # Proximity penalty exists since same-beer casks are already grouped
    # Deck penalty is zero since 5 slots = 5 casks

    cmp_ok( $score, '>=', 0, 'score is non-negative' );

    # Manually verify: all adjacent non-empty slots should be in order
    my $layout   = $p->_layout;
    my @occupied = grep { defined $_ } @$layout[ 0 .. $p->num_positions - 1 ];
    my $violations = 0;
    for my $i ( 0 .. $#occupied - 1 ) {
        $violations++ if $occupied[$i]->sort_key gt $occupied[ $i + 1 ]->sort_key;
    }
    is( $violations, 0, 'no alphabetical violations in initial layout' );
};

# ── Finish ────────────────────────────────────────────────────────────────────

use Scalar::Util qw(looks_like_number);

done_testing();
