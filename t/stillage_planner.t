use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::StillagePlanner' }
BEGIN { use_ok 'BeerFestDB::StillagePlanner::CaskEntry' }
BEGIN { use_ok 'BeerFestDB::StillagePlanner::Config' }
BEGIN { use_ok 'BeerFestDB::StillagePlanner::SlotGroup' }

my $s = schema();

# ── Test helpers ──────────────────────────────────────────────────────────────

my $CONFIG_FILE = 't/data/stillage_plan_test.yml';

sub make_config {
    return BeerFestDB::StillagePlanner::Config->new(
        config_file => $CONFIG_FILE,
    );
}

sub make_planner {
    my $fest = $s->resultset('Festival')->find(1);
    return BeerFestDB::StillagePlanner->new(
        database => $s,
        festival => $fest,
        config   => make_config(),
        @_,
    );
}

# ── Extra fixtures ────────────────────────────────────────────────────────────
#
# The pristine TestFestivalDB provides:
#   Festival 1, Company 1 (TestBrewer), Product 1 (TestBeer),
#   OrderBatch 1, StillageLocation 1 (TestStillage),
#   CaskManagement 1 (firkin, cellar_ref=1, stillage_location_id=1).
#
# We add:
#   - "PlannerTestStillage" (StillageLocation 2) for build_slot_groups to find
#   - BayPosition vocab rows (Top Front id=1, Bottom Front id=6)
#   - Two more companies/products, each with a ProductOrder and several
#     unassigned CaskManagement rows (stillage_location_id => undef)
#   - One SOR cask (is_sale_or_return=1) to exercise the SOR deck penalty

# PlannerTestStillage (referenced by t/data/stillage_plan_test.yml)
$s->resultset('StillageLocation')->find_or_create({
    stillage_location_id => 2,
    festival_id          => 1,
    description          => 'PlannerTestStillage',
});

# BayPosition vocab: Top Front = id 1, Bottom Front = id 6
# (from initialise_vocabs.sql; test DB may not have them yet)
$s->resultset('BayPosition')->find_or_create({ bay_position_id => 1, description => 'Top Front' });
$s->resultset('BayPosition')->find_or_create({ bay_position_id => 6, description => 'Bottom Front' });

# --- Company 2 / AardvarkBrew ---
$s->resultset('Company')->find_or_create({
    company_id        => 2,
    company_region_id => 5,
    name              => 'AardvarkBrew',
});
$s->resultset('Product')->find_or_create({
    product_id          => 2,
    company_id          => 2,
    product_category_id => 2,
    name                => 'Amber',
});

# ProductOrder 1: AardvarkBrew Amber firkins
$s->resultset('ProductOrder')->find_or_create({
    product_order_id       => 1,
    order_batch_id         => 1,
    product_id             => 2,
    distributor_company_id => 2,
    container_size_id      => 1,   # firkin
    cask_count             => 2,
    currency_id            => 1,
    is_sale_or_return      => 0,
});

# CaskManagement 2 & 3: two unassigned firkins for AardvarkBrew Amber
# cellar_reference 10/11 to avoid conflict with existing cm_id=1 (ref=1)
$s->resultset('CaskManagement')->find_or_create({
    cask_management_id   => 2,
    festival_id          => 1,
    container_size_id    => 1,   # firkin
    currency_id          => 1,
    product_order_id     => 1,
    stillage_location_id => undef,
    cellar_reference     => 10,
});
$s->resultset('CaskManagement')->find_or_create({
    cask_management_id   => 3,
    festival_id          => 1,
    container_size_id    => 1,
    currency_id          => 1,
    product_order_id     => 1,
    stillage_location_id => undef,
    cellar_reference     => 11,
});

# --- Company 3 / ZymurgyZone ---
$s->resultset('Company')->find_or_create({
    company_id        => 3,
    company_region_id => 5,
    name              => 'ZymurgyZone',
});
$s->resultset('Product')->find_or_create({
    product_id          => 3,
    company_id          => 3,
    product_category_id => 2,
    name                => 'Zenith',
});

# ProductOrder 2: ZymurgyZone Zenith firkins
$s->resultset('ProductOrder')->find_or_create({
    product_order_id       => 2,
    order_batch_id         => 1,
    product_id             => 3,
    distributor_company_id => 3,
    container_size_id      => 1,   # firkin
    cask_count             => 2,
    currency_id            => 1,
    is_sale_or_return      => 0,
});

# CaskManagement 4 & 5: two unassigned firkins for ZymurgyZone Zenith
# CaskManagement 5 is SOR (flag set directly on the cask_management row)
$s->resultset('CaskManagement')->find_or_create({
    cask_management_id   => 4,
    festival_id          => 1,
    container_size_id    => 1,
    currency_id          => 1,
    product_order_id     => 2,
    stillage_location_id => undef,
    cellar_reference     => 20,
});
$s->resultset('CaskManagement')->find_or_create({
    cask_management_id    => 5,
    festival_id           => 1,
    container_size_id     => 1,
    currency_id           => 1,
    product_order_id      => 2,
    stillage_location_id  => undef,
    cellar_reference      => 21,
    is_sale_or_return     => 1,
});

# ── Config tests ──────────────────────────────────────────────────────────────

subtest 'Config loads YAML correctly' => sub {
    my $cfg;
    lives_ok { $cfg = make_config() } 'Config->new lives';

    cmp_ok( $cfg->margin, '==', 0.10, 'margin is 0.10' );
    is( $cfg->container_width_for('firkin'),    0.45, 'firkin width 0.45' );
    is( $cfg->container_width_for('kilderkin'), 0.58, 'kilderkin width 0.58' );
    dies_ok { $cfg->container_width_for('nonexistent') }
        'container_width_for dies for unknown size';
    is( $cfg->weight('alphabetical', 10),       10,   'alpha weight 10' );
    is( $cfg->weight('proximity', 5),            5,   'prox weight 5' );
    is( $cfg->weight('stillage', 1000),       1000,   'stillage weight 1000' );
    is( $cfg->weight('deck', 20),               20,   'deck weight 20' );
    is( $cfg->weight('pull_through', 15),       15,   'pull_through weight 15' );
    is( $cfg->weight('sor_deck_multiplier', 0.1), 0.1,'SOR multiplier 0.1' );
    is( $cfg->initial_temperature, 1500, 'initial temperature 1500' );
    is( $cfg->cooling_rate, 0.99, 'cooling rate 0.99' );
    is( $cfg->temperature_floor, 0.5, 'temperature floor 0.5' );

    # product_categories is set in the test YAML
    my $cats = $cfg->product_categories;
    ok( defined $cats && ref($cats) eq 'ARRAY', 'product_categories returns arrayref' );
    is( $cats->[0], 'foreign beer', 'first category is foreign beer' );

    # dispense_methods is set in the test YAML
    my $dms = $cfg->dispense_methods;
    ok( defined $dms && ref($dms) eq 'ARRAY', 'dispense_methods returns arrayref' );
    is( $dms->[0], 'cask', 'first dispense method is cask' );
};

# ── product_categories filter test ───────────────────────────────────────────

subtest 'load_casks respects product_categories filter' => sub {
    # Config with product_categories: [beer] -- test products are all
    # 'foreign beer' (category_id=2), so the filter should exclude them all.
    my $filter_cfg = BeerFestDB::StillagePlanner::Config->new(
        config_file => 't/data/stillage_plan_filter_test.yml',
    );
    my $cats = $filter_cfg->product_categories;
    is( $cats->[0], 'beer', 'filter config has beer category' );

    my $fest = $s->resultset('Festival')->find(1);
    my $p = BeerFestDB::StillagePlanner->new(
        database => $s,
        festival => $fest,
        config   => $filter_cfg,
    );
    my $n;
    lives_ok { $n = $p->load_casks() } 'load_casks with category filter lives';
    is( $n, 0, 'category filter excludes all foreign beer casks' );
};

# ── dispense_methods filter test ──────────────────────────────────────────────

subtest 'load_casks respects dispense_methods filter' => sub {
    # Config with dispense_methods: [key keg] -- test casks all use
    # container_size_id=1 (firkin, dispense_method='cask'), so the filter
    # should exclude them all.
    my $dm_filter_cfg = BeerFestDB::StillagePlanner::Config->new(
        config_file => 't/data/stillage_plan_dm_filter_test.yml',
    );
    my $dms = $dm_filter_cfg->dispense_methods;
    is( $dms->[0], 'key keg', 'DM filter config has key keg method' );

    my $fest = $s->resultset('Festival')->find(1);
    my $p = BeerFestDB::StillagePlanner->new(
        database => $s,
        festival => $fest,
        config   => $dm_filter_cfg,
    );
    my $n;
    lives_ok { $n = $p->load_casks() } 'load_casks with DM filter lives';
    is( $n, 0, 'DM filter excludes all cask-dispense casks' );
};

# ── SlotGroup tests ───────────────────────────────────────────────────────────

subtest 'SlotGroup capacity_for and can_fit' => sub {
    my $sl  = $s->resultset('StillageLocation')->find(2);
    my $bp  = $s->resultset('BayPosition')->find(1);

    my $sg = BeerFestDB::StillagePlanner::SlotGroup->new(
        stillage_location => $sl,
        bay_number        => 1,
        bay_position      => $bp,
        width             => 4.0,
        margin            => 0.10,
    );

    # capacity = floor(4.0 / (0.45 * 1.1)) = floor(4.0 / 0.495) = floor(8.08) = 8
    is( $sg->capacity_for(0.45), 8, 'capacity_for firkin width = 8' );

    ok(  $sg->can_fit(0.0,  0.45), 'can fit first cask into empty slot' );
    ok(  $sg->can_fit(3.5,  0.45), 'can fit when sum is within width' );
    ok( !$sg->can_fit(3.6,  0.45), 'cannot fit when sum exceeds width' );
    # effective pitch = 0.45 * 1.1 = 0.495; 8 casks use 3.96m; 4.0 - 3.96 = 0.04 to spare
    ok(  $sg->can_fit(3.96, 0.001), 'can fit tiny cask into nearly-full slot' );

    is( $sg->bay_id,   '2:1',   'bay_id is stillage_id:bay_num' );
};

# ── build_slots test ──────────────────────────────────────────────────────────

subtest 'build_slots returns correct slot groups' => sub {
    my $p = make_planner();
    my $n;
    lives_ok { $n = $p->build_slots() } 'build_slots lives';

    # Config has 3 positions: Bay1/TopFront(4m), Bay1/BottomFront(3m), Bay2/TopFront(2m)
    is( $n, 3, 'build_slots returns 3 slot groups' );

    my $groups = $p->_slot_groups;
    cmp_ok( $groups->[0]->width, '==', 4.0, 'first group width 4.0' );
    cmp_ok( $groups->[1]->width, '==', 3.0, 'second group width 3.0' );
    cmp_ok( $groups->[2]->width, '==', 2.0, 'third group width 2.0' );
};

# ── load_casks test ───────────────────────────────────────────────────────────

subtest 'load_casks loads only unassigned casks' => sub {
    my $p = make_planner();
    my $n;
    lives_ok { $n = $p->load_casks() } 'load_casks lives';

    # CaskManagement 1 is already assigned (stillage_location_id=1) -- should be skipped
    # CaskManagement 2-5 are unassigned
    is( $n, 4, 'load_casks returns 4 unassigned casks' );

    my $entries = $p->_cask_entries;
    my @sor = grep { $_->is_sale_or_return } @$entries;
    is( scalar @sor, 1, 'one SOR cask loaded' );

    # Check cask_width is populated
    for my $e (@$entries) {
        ok( defined $e->cask_width && $e->cask_width > 0,
            'cask_width populated for ' . $e->label );
    }

    # Verify cask numbering within each beer
    my %by_product;
    push @{ $by_product{ $_->product_group_id } }, $_ for @$entries;
    for my $prod_id ( keys %by_product ) {
        my @beer = sort { $a->cask_number <=> $b->cask_number }
                        @{ $by_product{$prod_id} };
        is( $beer[0]->cask_number, 1,
            "first cask of product $prod_id numbered 1" );
        is( $beer[-1]->cask_count, scalar @beer,
            "cask_count matches total for product $prod_id" );
    }
};

# ── initialise test ───────────────────────────────────────────────────────────

subtest 'initialise builds a valid assignment' => sub {
    my $p = make_planner();
    $p->load_casks();
    $p->build_slots();
    lives_ok { $p->initialise() } 'initialise lives';

    my $assign = $p->_assignment;
    my $casks  = $p->_cask_entries;
    is( scalar @$assign, scalar @$casks, 'assignment length matches cask count' );

    # All assignments must be DECK_IDX(-1) or a valid group index
    my $n_groups = scalar @{ $p->_slot_groups };
    for my $ci ( 0 .. $#$assign ) {
        ok( $assign->[$ci] == BeerFestDB::StillagePlanner::DECK_IDX
                || ( $assign->[$ci] >= 0 && $assign->[$ci] < $n_groups ),
            "assignment[$ci] is valid (got $assign->[$ci])" );
    }

    # Used widths must be non-negative and <= group width
    my $used_w = $p->_used_width;
    my $groups = $p->_slot_groups;
    for my $gi ( 0 .. $#$groups ) {
        cmp_ok( $used_w->[$gi], '>=', 0,
            "used_w[$gi] >= 0" );
        cmp_ok( $used_w->[$gi], '<=', $groups->[$gi]->width + 1e-9,
            "used_w[$gi] <= group width" );
    }
};

# ── score test ────────────────────────────────────────────────────────────────

subtest 'score returns a non-negative number' => sub {
    my $p = make_planner();
    $p->load_casks();
    $p->build_slots();
    $p->initialise();

    my $s;
    lives_ok { $s = $p->score() } 'score lives';
    ok( defined $s, 'score returns a value' );
    cmp_ok( $s, '>=', 0, 'score is non-negative' );
};

# ── annealing test ───────────────────────────────────────────────────────────

subtest 'acceptance probability depends on temperature' => sub {
    is(
        BeerFestDB::StillagePlanner::_acceptance_probability( -1, 10 ),
        1,
        'improving moves are always accepted',
    );

    is(
        BeerFestDB::StillagePlanner::_acceptance_probability( 10, 0 ),
        0,
        'zero temperature rejects uphill moves',
    );

    cmp_ok(
        BeerFestDB::StillagePlanner::_acceptance_probability( 10, 20 ),
        '>',
        BeerFestDB::StillagePlanner::_acceptance_probability( 10, 5 ),
        'higher temperatures accept uphill moves more readily',
    );
};

# ── hill-climbing fallback test ──────────────────────────────────────────────

subtest 'negative initial_temperature falls back to pure hill-climbing' => sub {
    srand(42);
    my $hc_cfg = BeerFestDB::StillagePlanner::Config->new(
        config_file => 't/data/stillage_plan_hill_climbing_fallback_test.yml',
    );
    my $fest = $s->resultset('Festival')->find(1);
    my $p = BeerFestDB::StillagePlanner->new(
        database => $s,
        festival => $fest,
        config   => $hc_cfg,
    );
    $p->load_casks();
    $p->build_slots();
    $p->initialise();

    my $initial_score = $p->score();
    my $final_score;
    lives_ok { $final_score = $p->plan() } 'plan lives with negative initial_temperature';
    cmp_ok( $final_score, '<=', $initial_score,
        'plan score <= initial score under hill-climbing' );

    # A pure hill-climber can only ever accept moves that do not worsen
    # the score, so the acceptance probability for any uphill move must
    # be zero throughout (the temperature never becomes positive).
    is(
        BeerFestDB::StillagePlanner::_acceptance_probability( 10, $p->config->initial_temperature ),
        0,
        'uphill moves are never accepted when initial_temperature is negative',
    );
};

# ── plan test ─────────────────────────────────────────────────────────────────

subtest 'plan runs without error and returns a score' => sub {
    srand(42);
    my $p = make_planner( max_iterations => 200, convergence_streak => 50 );
    $p->load_casks();
    $p->build_slots();
    $p->initialise();

    my $initial_score = $p->score();
    my $final_score;
    lives_ok { $final_score = $p->plan() } 'plan lives';
    cmp_ok( $final_score, '<=', $initial_score,
        'plan score <= initial score' );
};

# ── render test ───────────────────────────────────────────────────────────────

subtest 'render returns a non-empty string' => sub {
    my $p = make_planner();
    $p->load_casks();
    $p->build_slots();
    $p->initialise();

    my $out;
    lives_ok { $out = $p->render() } 'render lives';
    ok( defined $out && length($out) > 0, 'render returns non-empty string' );
    like( $out, qr/Score:/, 'render output contains Score:' );
};

# ── apply test ────────────────────────────────────────────────────────────────

subtest 'apply writes stillage_location_id, stillage_bay, bay_position_id' => sub {
    my $p = make_planner();
    $p->load_casks();
    $p->build_slots();
    $p->initialise();
    lives_ok { $p->apply() } 'apply lives';

    my $casks  = $p->_cask_entries;
    my $groups = $p->_slot_groups;
    my $assign = $p->_assignment;

    for my $ci ( 0 .. $#$casks ) {
        my $cm = $casks->[$ci]->cask_management;
        $cm->discard_changes;
        my $gi = $assign->[$ci];

        if ( $gi == BeerFestDB::StillagePlanner::DECK_IDX ) {
            is( $cm->cask_graveyard,       'deck', "deck cask $ci: cask_graveyard='deck'" );
            is( $cm->get_column('stillage_location_id'), undef,  "deck cask $ci: stillage_location_id is undef" );
            is( $cm->get_column('stillage_bay'),         undef,  "deck cask $ci: stillage_bay is undef" );
            is( $cm->get_column('bay_position_id'),      undef,  "deck cask $ci: bay_position_id is undef" );
        }
        else {
            my $g = $groups->[$gi];
            is( $cm->get_column('stillage_location_id'),
                $g->stillage_location->get_column('stillage_location_id'),
                "on-stillage cask $ci: correct stillage_location_id" );
            is( $cm->get_column('stillage_bay'), $g->bay_number,
                "on-stillage cask $ci: correct stillage_bay" );
            is( $cm->get_column('bay_position_id'),
                $g->bay_position->get_column('bay_position_id'),
                "on-stillage cask $ci: correct bay_position_id" );
            isnt( $cm->cask_graveyard, 'deck',
                "on-stillage cask $ci: not in graveyard" );
        }
    }

    # Verify x/y/z were NOT touched (should remain undef for our new casks)
    for my $ci ( 0 .. $#$casks ) {
        my $cm = $casks->[$ci]->cask_management;
        $cm->discard_changes;
        is( $cm->get_column('stillage_x_location'), undef,
            "cask $ci: stillage_x_location not set by apply" );
    }
};

# ── Finish ────────────────────────────────────────────────────────────────────

done_testing();
