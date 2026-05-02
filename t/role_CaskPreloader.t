use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Role::CaskPreloader' }

# Minimal Moose consumer (CaskPreloader has no 'requires' clauses).
{
    package TestCaskPreloader;
    use Moose;
    with 'BeerFestDB::Role::CaskPreloader';
    no Moose;
}

my $s         = schema();
my $preloader = TestCaskPreloader->new();

# ── Fixtures ─────────────────────────────────────────────────────────────────
# ProductOrder 1: used to test preload_cask_managements in isolation.
# Start with is_final=0 so we can check the "no caskmans" path first.
my $po1 = $s->resultset('ProductOrder')->find_or_create({
    order_batch_id         => 1,
    product_id             => 1,
    distributor_company_id => 1,   # TestBrewer
    container_size_id      => 1,   # firkin
    cask_count             => 2,
    currency_id            => 1,   # GBP
    is_final               => 0,
    is_received            => 1,
    is_sale_or_return      => 0,
});

# ProductOrder 2: used to test the full preload_product_order path.
my $po2 = $s->resultset('ProductOrder')->find_or_create({
    order_batch_id         => 1,
    product_id             => 1,
    distributor_company_id => 1,
    container_size_id      => 1,
    cask_count             => 1,
    currency_id            => 1,
    is_final               => 1,
    is_received            => 1,
    is_sale_or_return      => 0,
});

# ── preload_cask_managements: is_final=0 ─────────────────────────────────────

lives_ok { local $SIG{__WARN__} = sub {}; $preloader->preload_cask_managements($po1) }
    'preload_cask_managements lives with is_final=0';

is( $po1->cask_managements()->count(), 0,
    'preload_cask_managements with is_final=0 creates no CaskManagement records' );

# ── preload_cask_managements: is_final=1 → creates caskmans ──────────────────

$po1->update({ is_final => 1 });

lives_ok { local $SIG{__WARN__} = sub {}; $preloader->preload_cask_managements($po1) }
    'preload_cask_managements lives with is_final=1, cask_count=2';

is( $po1->cask_managements()->count(), 2,
    'preload_cask_managements with is_final=1, cask_count=2 creates 2 CaskManagement records' );

# Cellar references must follow on from the existing fixture max (1).
my @caskmans = sort { $a->cellar_reference <=> $b->cellar_reference }
                   $po1->cask_managements()->all();
is( $caskmans[0]->cellar_reference, 2,
    'first new CaskManagement has cellar_reference=2' );
is( $caskmans[1]->cellar_reference, 3,
    'second new CaskManagement has cellar_reference=3' );

# All new CaskManagements must link back to po1.
for my $cm (@caskmans) {
    is( $cm->get_column('product_order_id'), $po1->product_order_id,
        'CaskManagement.product_order_id links back to the correct product order' );
}

# CaskManagement attributes should mirror the ProductOrder.
is( $caskmans[0]->get_column('container_size_id'), 1,
    'CaskManagement.container_size_id matches the product order' );
is( $caskmans[0]->get_column('festival_id'), 1,
    'CaskManagement.festival_id is set correctly from the order batch' );

# ── preload_cask_managements: idempotent ─────────────────────────────────────

lives_ok { local $SIG{__WARN__} = sub {}; $preloader->preload_cask_managements($po1) }
    'preload_cask_managements is idempotent (second call lives)';

is( $po1->cask_managements()->count(), 2,
    'preload_cask_managements is idempotent (count stays at 2)' );

# ── preload_product_order ─────────────────────────────────────────────────────

my $fp_count_before   = $s->resultset('FestivalProduct')->count();
my $gyle_count_before = $s->resultset('Gyle')->count();

lives_ok { local $SIG{__WARN__} = sub {}; $preloader->preload_product_order($po2) }
    'preload_product_order lives';

# The FestivalProduct for festival 1 / product 1 already exists — no new one.
is( $s->resultset('FestivalProduct')->count(), $fp_count_before,
    'preload_product_order finds the existing FestivalProduct rather than creating a duplicate' );

# Exactly one new Gyle (internal_reference='auto-generated') should be added.
is( $s->resultset('Gyle')->count(), $gyle_count_before + 1,
    'preload_product_order creates exactly one new Gyle' );

my $auto_gyle = $s->resultset('Gyle')->find({
    company_id          => 1,
    festival_product_id => 1,
    internal_reference  => 'auto-generated',
});
ok( defined $auto_gyle,
    'auto-generated Gyle exists in the database' );

# One CaskManagement linked to po2.
is( $po2->cask_managements()->count(), 1,
    'preload_product_order creates 1 CaskManagement for the product order' );

# A Cask must be wired to the new CaskManagement and the auto-generated Gyle.
my ($new_cm) = $po2->cask_managements()->all();

my $new_cask = $s->resultset('Cask')->find({
    cask_management_id => $new_cm->cask_management_id,
    gyle_id            => $auto_gyle->gyle_id,
});
ok( defined $new_cask,
    'preload_product_order creates a Cask linked to the new CaskManagement and Gyle' );

# ── preload_product_order: idempotent ─────────────────────────────────────────

lives_ok { local $SIG{__WARN__} = sub {}; $preloader->preload_product_order($po2) }
    'preload_product_order is idempotent (second call lives)';

is( $po2->cask_managements()->count(), 1,
    'preload_product_order is idempotent (CaskManagement count stays at 1)' );

done_testing();
