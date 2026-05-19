#
# This file is part of BeerFestDB, a beer festival product management
# system.
#
# Copyright (C) 2010-2026 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

package BeerFestDB::StillagePlanner;

use 5.008;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Carp;
use Digest::MD5 qw(md5_hex);

use BeerFestDB::StillagePlanner::CaskEntry;
use BeerFestDB::StillagePlanner::Config;
use BeerFestDB::StillagePlanner::SlotGroup;

our $VERSION = '0.01';

# Sentinel value for "assigned to deck"
use constant DECK_IDX => -1;

=head1 NAME

BeerFestDB::StillagePlanner - Automated assignment of casks to stillage positions

=head1 SYNOPSIS

  use BeerFestDB::ORM;
  use BeerFestDB::StillagePlanner;
  use BeerFestDB::StillagePlanner::Config;

  my $schema  = BeerFestDB::ORM->connect($dsn);
  my $config  = BeerFestDB::StillagePlanner::Config->new(
                    config_file => 'stillage_plan.yml' );
  my $festival = $schema->resultset('Festival')->find(1);

  my $planner = BeerFestDB::StillagePlanner->new(
      database => $schema,
      festival => $festival,
      config   => $config,
  );

  my $n_casks  = $planner->load_casks();
  my $n_groups = $planner->build_slots();
  $planner->initialise();
  my $score = $planner->plan();
  print $planner->render();
  $planner->apply();   # writes stillage_location_id, stillage_bay,
                       # and bay_position_id back to the DB

=head1 DESCRIPTION

C<BeerFestDB::StillagePlanner> assigns unplaced casks (C<cask_management>
rows whose C<stillage_location_id> is NULL) to bay positions across one
or more named stillages, minimising a configurable penalty score.

The physical constraints come from a YAML configuration file (see
L<BeerFestDB::StillagePlanner::Config>):

=over 4

=item * Each container size has a B<physical width> (in metres).

=item * Each bay position within each stillage bay has a B<physical
width>.

=item * A B<margin fraction> (default 10 %) is added to each cask width,
so the effective pitch of a cask is C<cask_width x (1 + margin)>.  A
bay position can therefore hold at most
C<floor(bay_width / effective_cask_pitch)> casks.

=back

Capacity is enforced as a hard constraint: the hill-climber never
proposes a swap that would overfill a slot group.

The penalty score combines three soft objectives:

=over 4

=item * B<Alphabetical order> - casks should appear in brewery/beer
name order when reading across all slot groups in sequence.

=item * B<Beer proximity> - casks from the same product should be in
the same bay.

=item * B<Deck placement> - casks that cannot fit on the stillage
receive an importance-weighted penalty (first cask worst, last cask
least), with a much lower penalty for sale-or-return casks.

=back

=head1 ATTRIBUTES

=head2 database

A connected L<DBIx::Class::Schema> instance.  Required.

=cut

has 'database' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

=head2 festival

A L<BeerFestDB::ORM::Festival> row identifying which festival's
unassigned casks to plan.  Required.

=cut

has 'festival' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 config

A L<BeerFestDB::StillagePlanner::Config> instance.  Required.

=cut

has 'config' => (
    is       => 'ro',
    isa      => 'BeerFestDB::StillagePlanner::Config',
    required => 1,
);

=head2 max_iterations

Maximum number of swap attempts before giving up (default 5000).

=cut

has 'max_iterations' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5000,
);

=head2 convergence_streak

Stop when this many consecutive swap attempts fail to improve the
score (default 500).

=cut

has 'convergence_streak' => (
    is      => 'ro',
    isa     => 'Int',
    default => 500,
);

# ── Internal state ────────────────────────────────────────────────────────────

# Ordered list of CaskEntry objects (sorted alphabetically after initialise())
has '_cask_entries' => (
    is      => 'rw',
    isa     => 'ArrayRef[BeerFestDB::StillagePlanner::CaskEntry]',
    default => sub { [] },
);

# Ordered list of SlotGroup objects built from the config
has '_slot_groups' => (
    is      => 'rw',
    isa     => 'ArrayRef[BeerFestDB::StillagePlanner::SlotGroup]',
    default => sub { [] },
);

# _assignment[i] = slot group index for _cask_entries[i], or DECK_IDX
has '_assignment' => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub { [] },
);

# _used_width[gi] = sum of effective widths (cask_width*(1+margin))
#                   for all casks currently assigned to group gi
has '_used_width' => (
    is      => 'rw',
    isa     => 'ArrayRef[Num]',
    default => sub { [] },
);

# ── Public methods ────────────────────────────────────────────────────────────

=head1 METHODS

=head2 load_casks

Loads all active, unassigned C<cask_management> rows for the planner's
festival from the database (i.e. rows where C<stillage_location_id> is
NULL and C<cask_graveyard> is NULL, and whose linked C<cask> is not
condemned).

For each row the brewery name, beer name, container type, and physical
width are resolved via the ORM and the config.  Cask numbers within
each beer are assigned in ascending C<cellar_reference> order.

Casks whose container size description is absent from the config are
skipped with a warning.

Returns the number of cask entries loaded.

=cut

sub load_casks {
    my ($self) = @_;

    my $db          = $self->database;
    my $festival_id = $self->festival->get_column('festival_id');
    my $config      = $self->config;

    my @caskmans = $db->resultset('CaskManagement')->search(
        {
            festival_id          => $festival_id,
            stillage_location_id => undef,
            cask_graveyard       => undef,
        },
    )->all;

    my @entries;
    for my $cm (@caskmans) {

        # Resolve product and brewery via product_order.  This path works
        # before the cask/festival_product tables have been populated.
        my $po = $cm->product_order_id;
        unless ( defined $po ) {
            warn "Skipping cask_management "
                . $cm->get_column('cask_management_id')
                . ": no product_order_id set\n";
            next;
        }

        my $product      = $po->product_id;
        my $company      = $product->company_id;

        my $beer_name    = $product->name;
        my $brewery_name = $company->name;
        my $prod_id      = $product->get_column('product_id');
        my $sort_key     = lc("$brewery_name $beer_name");

        my $container_type = $cm->container_size_id->description;

        my $cask_width;
        eval { $cask_width = $config->container_width_for($container_type) };
        if ($@) {
            warn "Skipping cask_management "
                . $cm->get_column('cask_management_id')
                . ": $@";
            next;
        }

        push @entries, BeerFestDB::StillagePlanner::CaskEntry->new(
            cask_management     => $cm,
            beer_name           => $beer_name,
            brewery_name        => $brewery_name,
            sort_key            => $sort_key,
            cask_number         => 1,      # placeholder; corrected below
            cask_count          => 1,      # placeholder; corrected below
            is_sale_or_return   => ( $cm->is_sale_or_return // 0 ) ? 1 : 0,
            container_type      => $container_type,
            product_group_id    => $prod_id,
            cask_width          => $cask_width,
        );
    }

    # Number casks within each beer by ascending cellar_reference
    my %by_product;
    for my $entry (@entries) {
        push @{ $by_product{ $entry->product_group_id } }, $entry;
    }

    for my $prod_id ( sort keys %by_product ) {
        my @beer_casks = sort {
            $a->cask_management->get_column('cellar_reference')
                <=> $b->cask_management->get_column('cellar_reference')
        } @{ $by_product{$prod_id} };

        my $count = scalar @beer_casks;
        for my $i ( 0 .. $#beer_casks ) {
            $beer_casks[$i]->cask_number( $i + 1 );
            $beer_casks[$i]->cask_count($count);
        }
    }

    $self->_cask_entries( \@entries );
    return scalar @entries;
}

=head2 build_slots

Constructs the list of L<BeerFestDB::StillagePlanner::SlotGroup>
objects from the YAML config, resolving C<StillageLocation> and
C<BayPosition> rows against the database.

Must be called before L</initialise>.  Returns the number of slot
groups created.

=cut

sub build_slots {
    my ($self) = @_;
    my $groups = $self->config->build_slot_groups( $self->database );
    $self->_slot_groups($groups);
    return scalar @$groups;
}

=head2 initialise

Builds the initial assignment by sorting all loaded cask entries
alphabetically (by C<sort_key>, then C<cask_number>) and assigning
them to slot groups in config order using a greedy first-fit strategy.
Casks that cannot fit in any slot group are assigned to the deck.

Must be called after both L</load_casks> and L</build_slots>.

=cut

sub initialise {
    my ($self) = @_;

    croak 'Call load_casks() and build_slots() before initialise()'
        unless @{ $self->_cask_entries } && @{ $self->_slot_groups };

    my @sorted = sort {
            $a->sort_key    cmp $b->sort_key
        ||  $a->cask_number <=> $b->cask_number
    } @{ $self->_cask_entries };

    my $groups   = $self->_slot_groups;
    my $n_groups = scalar @$groups;
    my $margin   = $self->config->margin;

    my @used_w = (0) x $n_groups;
    my @assign;

  CASK: for my $ci ( 0 .. $#sorted ) {
        my $cw = $sorted[$ci]->cask_width;

        for my $gi ( 0 .. $n_groups - 1 ) {
            if ( $groups->[$gi]->can_fit( $used_w[$gi], $cw ) ) {
                $assign[$ci]  = $gi;
                $used_w[$gi] += $cw * ( 1 + $margin );
                next CASK;
            }
        }

        # No group has room – overflow to deck
        $assign[$ci] = DECK_IDX;
    }

    # Store sorted entries so _assignment[i] <-> _cask_entries[i] are consistent
    $self->_cask_entries( \@sorted );
    $self->_assignment( \@assign );
    $self->_used_width( \@used_w );
    return;
}

=head2 score

Returns the total penalty score for the current assignment.  Lower is
better.

=cut

sub score {
    my ($self) = @_;
    return $self->_score_assignment( $self->_assignment, $self->_used_width );
}

=head2 plan

Runs the random-pair-swap hill-climber.  Only swaps that satisfy the
physical width constraints of both affected slot groups are considered.

Stops when the C<convergence_streak> consecutive non-improving swaps
threshold is reached, when C<max_iterations> have been attempted, or
when a previously seen assignment state (cycle) is detected.

Returns the final total score.

=cut

sub plan {
    my ($self) = @_;

    croak 'Call initialise() before plan()'
        unless @{ $self->_assignment };

    my $casks     = $self->_cask_entries;
    my $groups    = $self->_slot_groups;
    my $n_casks   = scalar @$casks;
    my $margin    = $self->config->margin;

    my @assign    = @{ $self->_assignment };
    my @used_w    = @{ $self->_used_width };

    my $cur_score = $self->_score_assignment( \@assign, \@used_w );
    my $no_improv = 0;
    my %seen      = ( _state_string( \@assign ) => 1 );

  ITER: for my $iter ( 1 .. $self->max_iterations ) {

        my ( $i, $j ) = _random_pair($n_casks);
        my $gi = $assign[$i];
        my $gj = $assign[$j];

        next ITER if $gi == $gj;    # same group, no-op

        my $wi = $casks->[$i]->cask_width * ( 1 + $margin );
        my $wj = $casks->[$j]->cask_width * ( 1 + $margin );

        # Hard width-constraint check: would either group overflow after swap?
        if ( $gi != DECK_IDX ) {
            my $new_w = $used_w[$gi] - $wi + $wj;
            next ITER if $new_w > $groups->[$gi]->width + 1e-9;
        }
        if ( $gj != DECK_IDX ) {
            my $new_w = $used_w[$gj] - $wj + $wi;
            next ITER if $new_w > $groups->[$gj]->width + 1e-9;
        }

        # Tentative swap
        @assign[ $i, $j ] = @assign[ $j, $i ];
        $used_w[$gi] += $wj - $wi if $gi != DECK_IDX;
        $used_w[$gj] += $wi - $wj if $gj != DECK_IDX;

        my $new_score = $self->_score_assignment( \@assign, \@used_w );

        if ( $new_score < $cur_score ) {
            $cur_score = $new_score;
            $no_improv = 0;

            my $state = _state_string( \@assign );
            if ( $seen{$state} ) {
                # Cycle detected - revert and stop
                @assign[ $i, $j ] = @assign[ $j, $i ];
                $used_w[$gi] += $wi - $wj if $gi != DECK_IDX;
                $used_w[$gj] += $wj - $wi if $gj != DECK_IDX;
                last ITER;
            }
            $seen{$state} = 1;
        }
        else {
            # Revert
            @assign[ $i, $j ] = @assign[ $j, $i ];
            $used_w[$gi] += $wi - $wj if $gi != DECK_IDX;
            $used_w[$gj] += $wj - $wi if $gj != DECK_IDX;

            last ITER if ++$no_improv >= $self->convergence_streak;
        }
    }

    $self->_assignment( \@assign );
    $self->_used_width( \@used_w );
    return $cur_score;
}

=head2 apply

Writes the current planned assignment back to the database inside a
single transaction.

For on-stillage casks, sets C<stillage_location_id>, C<stillage_bay>,
and C<bay_position_id>, and clears C<cask_graveyard>.

For deck casks, NULLs all three location fields and sets
C<cask_graveyard> to C<"deck">.

Note: C<stillage_x_location>, C<stillage_y_location>, and
C<stillage_z_location> are not modified.

=cut

sub apply {
    my ($self) = @_;

    my $db     = $self->database;
    my $casks  = $self->_cask_entries;
    my $groups = $self->_slot_groups;
    my $assign = $self->_assignment;

    $db->txn_do(
        sub {
            for my $ci ( 0 .. $#$casks ) {
                my $cm = $casks->[$ci]->cask_management;
                my $gi = $assign->[$ci];

                if ( $gi != DECK_IDX ) {
                    my $g = $groups->[$gi];
                    $cm->update(
                        {
                            stillage_location_id => $g->stillage_location
                                ->get_column('stillage_location_id'),
                            stillage_bay    => $g->bay_number,
                            bay_position_id => $g->bay_position
                                ->get_column('bay_position_id'),
                            cask_graveyard => undef,
                        }
                    );
                }
                else {
                    $cm->update(
                        {
                            stillage_location_id => undef,
                            stillage_bay         => undef,
                            bay_position_id      => undef,
                            cask_graveyard       => 'deck',
                        }
                    );
                }
            }
        }
    );

    return;
}

=head2 render

Returns a human-readable multi-line string of the current planned
assignment, grouped by slot group.  Includes effective width usage per
slot group, and a separate deck section for overflow casks.

=cut

sub render {
    my ($self) = @_;

    my $casks  = $self->_cask_entries;
    my $groups = $self->_slot_groups;
    my $assign = $self->_assignment;
    my $used_w = $self->_used_width;

    my @lines;
    push @lines, sprintf( "Score: %.1f\n", $self->score );

    my %by_gi;
    my @deck;
    for my $ci ( 0 .. $#$casks ) {
        my $gi = $assign->[$ci];
        if ( $gi == DECK_IDX ) {
            push @deck, $casks->[$ci];
        }
        else {
            push @{ $by_gi{$gi} }, $casks->[$ci];
        }
    }

    for my $gi ( 0 .. $#$groups ) {
        my $group  = $groups->[$gi];
        my $uw     = $used_w->[$gi] // 0;
        my @in_grp = sort { $a->sort_key cmp $b->sort_key }
                         @{ $by_gi{$gi} // [] };

        push @lines, sprintf( '[%s]  %.2fm / %.2fm used',
            $group->label, $uw, $group->width );

        if (@in_grp) {
            push @lines, '  ' . $_->label for @in_grp;
        }
        else {
            push @lines, '  (empty)';
        }
        push @lines, '';
    }

    if (@deck) {
        push @lines, '--- DECK ---';
        push @lines, '  ' . $_->label
            for sort { $a->sort_key cmp $b->sort_key } @deck;
        push @lines, '';
    }

    return join( "\n", @lines );
}

# ── Private helpers ───────────────────────────────────────────────────────────

sub _score_assignment {
    my ( $self, $assign, $used_w ) = @_;

    my $casks  = $self->_cask_entries;
    my $groups = $self->_slot_groups;
    my $config = $self->config;

    my $w_alpha  = $config->weight( 'alphabetical',        10 );
    my $w_prox   = $config->weight( 'proximity',            5 );
    my $w_deck   = $config->weight( 'deck',                20 );
    my $sor_mult = $config->weight( 'sor_deck_multiplier', 0.1 );

    my $score = 0;

    # ── 1. Alphabetical order ─────────────────────────────────────────────
    # Build the physical sequence: sort non-deck casks by (group_index, sort_key)
    my @seq = sort {
            $assign->[$a] <=> $assign->[$b]
        ||  $casks->[$a]->sort_key cmp $casks->[$b]->sort_key
    } grep { $assign->[$_] != DECK_IDX } 0 .. $#$casks;

    for my $k ( 0 .. $#seq - 1 ) {
        $score += $w_alpha
            if $casks->[ $seq[$k] ]->sort_key
                gt $casks->[ $seq[ $k + 1 ] ]->sort_key;
    }

    # ── 2. Beer proximity ──────────────────────────────────────────────────
    # Penalty per extra distinct (stillage, bay) pair a beer occupies
    my %beer_bays;
    for my $ci ( 0 .. $#$casks ) {
        my $gi = $assign->[$ci];
        next if $gi == DECK_IDX;
        my $bay_id = $groups->[$gi]->bay_id;
        $beer_bays{ $casks->[$ci]->product_group_id }{$bay_id} = 1;
    }
    for my $prod_id ( keys %beer_bays ) {
        my $n = scalar keys %{ $beer_bays{$prod_id} };
        $score += ( $n - 1 ) * $w_prox if $n > 1;
    }

    # ── 3. Deck placement ─────────────────────────────────────────────────
    for my $ci ( 0 .. $#$casks ) {
        next if $assign->[$ci] != DECK_IDX;
        my $e          = $casks->[$ci];
        my $importance = $e->cask_count + 1 - $e->cask_number;
        my $penalty    = $importance * $w_deck;
        $penalty *= $sor_mult if $e->is_sale_or_return;
        $score += $penalty;
    }

    return $score;
}

# Compact fingerprint of the current assignment for cycle detection.
sub _state_string {
    my ($assign) = @_;
    return md5_hex( join( ',', @$assign ) );
}

# Returns two distinct random indices in [0, $n-1].
sub _random_pair {
    my ($n) = @_;
    my $i = int( rand($n) );
    my $j;
    do { $j = int( rand($n) ) } while $j == $i;
    return ( $i, $j );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SCORING DETAILS

The penalty score combines three components.  All weights can be
overridden in the C<weights> section of the YAML config file.

=over 4

=item B<Alphabetical order> (default weight 10)

The on-stillage casks are ordered by slot group index then sort key to
form the physical reading sequence.  Each adjacent pair in that
sequence that is out of alphabetical order adds one weight unit.

=item B<Beer proximity> (default weight 5)

For each beer with multiple on-stillage casks, the penalty is
C<(number of distinct (stillage, bay) pairs - 1) x weight>.  This
encourages all casks of the same beer to land in the same bay.

=item B<Deck placement> (default weight 20; SOR multiplier 0.1)

Each deck cask receives
C<(cask_count + 1 - cask_number) x weight x (SOR_multiplier if SOR)>
as a penalty.  The first cask of a beer is penalised most; the last
least.  Sale-or-return casks receive a much smaller penalty.

=back

=head1 ALGORITHM

Starting from a greedy alphabetical first-fit initial assignment,
L</plan> applies a random-pair-swap hill-climber:

=over 4

=item 1. Two cask indices are chosen uniformly at random.

=item 2. Their slot group assignments are swapped provisionally.

=item 3. If the swap would overfill either slot group (width constraint),
it is immediately rejected.

=item 4. Otherwise the new score is computed.  If it improved, the swap
is kept; otherwise it is reverted.

=item 5. After C<convergence_streak> consecutive non-improving swaps, or
after C<max_iterations> attempts, or upon detecting a previously seen
assignment state, the loop terminates.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

