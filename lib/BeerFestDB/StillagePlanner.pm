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

Capacity is enforced as a hard constraint: the annealer never accepts a
swap that would overfill a slot group.

The penalty score combines three soft objectives:

=over 4

=item * B<Alphabetical order> - casks should appear in brewery/beer
name order when reading across all slot groups in sequence.

=item * B<Beer proximity> - casks from the same product should be in
the same bay.

=item * B<Beer on same stillage> - casks from the same product really
must be on the same stillage.

=item * B<Deck placement> - casks that cannot fit on the stillage
receive an importance-weighted penalty (first cask worst, last cask
least), with a much lower penalty for sale-or-return casks.

=item * B<Pull-through placement> - casks from the same product should
be assigned within a given stillage level (e.g. Top or Bottom) so that
they can be aligned front-to-back for pull-through dispensing.

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

=head2 config

A L<BeerFestDB::StillagePlanner::Config> instance.  Required.

=cut

has 'config' => (
    is       => 'ro',
    isa      => 'BeerFestDB::StillagePlanner::Config',
    required => 1,
);

=head2 max_iterations

Maximum number of simulated-annealing iterations before giving up
(default 5000).

=cut

has 'max_iterations' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5000,
);

=head2 convergence_streak

Optional early stop once the search has cooled to the temperature
floor and this many consecutive iterations have failed to improve the
best score (default 500).

=cut

has 'convergence_streak' => (
    is      => 'ro',
    isa     => 'Int',
    default => 500,
);

=head2 trace_filehandle

If set to a filehandle, each attempted move is logged to it in CSV
format:

  ITERATION_NUMBER,TEMPERATURE,BEST_SCORE,SCORE,NEW_SCORE,I,J,G1,G2,MOVE_TYPE

Where I and J are the cask indices (equal for relocation moves), G1
and G2 are the slot group indices (I<from> and I<to>), and MOVE_TYPE
is C<S> for a swap or C<R> for a relocation.

=cut

has 'trace_filehandle' => (
    is      => 'rw',
    isa     => 'Maybe[FileHandle]',
    default => undef,
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

with 'BeerFestDB::Role::MenuSelector';

# ── Public methods ────────────────────────────────────────────────────────────

=head1 METHODS

=head2 load_casks

Loads all active, unassigned C<cask_management> rows for the planner's
festival from the database (i.e. rows where C<stillage_location_id> is
NULL).  Product and brewery information
is resolved via the linked C<product_order>.

If the config specifies a C<product_categories> list, only casks whose
product belongs to one of the named categories are included; all others
are silently skipped.

If the config specifies a C<dispense_methods> list, only casks whose
container size has a matching dispense method are included; all others
are silently skipped.

Casks whose C<product_order_id> is NULL, or whose container size
description is absent from the config, are skipped with a warning.

Cask numbers within each product are assigned in ascending
C<cellar_reference> order.

Returns the number of cask entries loaded.

=cut

sub load_casks {
    my ($self) = @_;

    my $db          = $self->database;
    my $festival_id = $self->festival->get_column('festival_id');
    my $config      = $self->config;

    # Build a category allowlist (lower-cased) if the config restricts
    # which product categories to include.  Empty hash → no restriction.
    my %allowed_categories;
    if ( my $cats = $config->product_categories ) {
        %allowed_categories = map { lc($_) => 1 } @$cats;
    }

    # Build a dispense-method allowlist (lower-cased) if configured.
    my %allowed_dispense_methods;
    if ( my $dms = $config->dispense_methods ) {
        %allowed_dispense_methods = map { lc($_) => 1 } @$dms;
    }

    my @caskmans = $db->resultset('CaskManagement')->search(
        {
            festival_id          => $festival_id,
            stillage_location_id => undef,
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

        # Apply product category filter if one is configured
        if ( %allowed_categories ) {
            my $cat = lc( $product->product_category_id->description );
            next unless $allowed_categories{$cat};
        }

        my $beer_name    = $product->name;
        my $brewery_name = $company->name;
        my $prod_id      = $product->get_column('product_id');
        my $sort_key     = lc("$brewery_name $beer_name");

        my $cs             = $cm->container_size_id;
        my $container_type = $cs->description;

        # Apply dispense method filter if one is configured
        if ( %allowed_dispense_methods ) {
            my $dm = lc( $cs->dispense_method_id->description );
            next unless $allowed_dispense_methods{$dm};
        }

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
    my $groups = $self->config->build_slot_groups( $self->database, $self->festival );
    $self->_slot_groups($groups);
    return scalar @$groups;
}

=head2 initialise

Builds the initial assignment by sorting all loaded cask entries
alphabetically (by C<sort_key>, then C<cask_number>), then placing
them beer-by-beer using a greedy first-fit strategy.

Each beer is placed entirely within a single stillage location: for
every stillage, a trial first-fit placement of the beer's casks is
simulated across just that stillage's slot groups, and the stillage
that can accommodate the most of them is used.  Any casks of the beer
that do not fit there are sent to the deck rather than being placed on
a different stillage, so a beer is never split across stillages.

If C<initial_deck_reserve> is configured (see
L<BeerFestDB::StillagePlanner::Config/initial_deck_reserve>), that
many casks are then deliberately evicted back to the deck from each
slot group, freeing capacity for L</plan> to work with.

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

    # Slot group indices grouped by stillage, in first-seen (config) order.
    my ( @stillage_ids, %stillage_group_idx );
    for my $gi ( 0 .. $n_groups - 1 ) {
        my $sl_id = $groups->[$gi]->stillage_location->get_column('stillage_location_id');
        push @stillage_ids, $sl_id unless exists $stillage_group_idx{$sl_id};
        push @{ $stillage_group_idx{$sl_id} }, $gi;
    }

    my @used_w = (0) x $n_groups;
    my @assign = (DECK_IDX) x scalar(@sorted);

    # Process casks beer-by-beer (contiguous runs after the alphabetical
    # sort, since all of a beer's casks share the same sort_key) so that
    # a beer is never split across stillage locations.
    my $ci = 0;
    while ( $ci <= $#sorted ) {
        my $prod_id = $sorted[$ci]->product_group_id;
        my $start   = $ci;
        $ci++ while $ci <= $#sorted && $sorted[$ci]->product_group_id == $prod_id;
        my @beer_idx = ( $start .. $ci - 1 );

        my ( $best_placement, $best_count ) = ( {}, -1 );

        for my $sl_id (@stillage_ids) {
            my @trial_used = @used_w;
            my %placement;
            my $count = 0;

            for my $bi (@beer_idx) {
                my $cw = $sorted[$bi]->cask_width;
                for my $gi ( @{ $stillage_group_idx{$sl_id} } ) {
                    if ( $groups->[$gi]->can_fit( $trial_used[$gi], $cw ) ) {
                        $placement{$bi} = $gi;
                        $trial_used[$gi] += $cw * ( 1 + $margin );
                        $count++;
                        last;
                    }
                }
            }

            if ( $count > $best_count ) {
                $best_count     = $count;
                $best_placement = \%placement;
            }
            last if $best_count == scalar(@beer_idx);
        }

        for my $bi (@beer_idx) {
            if ( exists $best_placement->{$bi} ) {
                my $gi = $best_placement->{$bi};
                $assign[$bi]  = $gi;
                $used_w[$gi] += $sorted[$bi]->cask_width * ( 1 + $margin );
            }
        }
    }

    # Deliberately free up space for the annealer: evict the last
    # $reserve casks placed in each slot group back to the deck.
    if ( my $reserve = $self->config->initial_deck_reserve ) {
        for my $gi ( 0 .. $n_groups - 1 ) {
            my @occupants = grep { $assign[$_] == $gi } 0 .. $#sorted;
            my $n_evict   = $reserve < @occupants ? $reserve : scalar @occupants;
            next unless $n_evict;

            for my $bi ( @occupants[ scalar(@occupants) - $n_evict .. $#occupants ] ) {
                $used_w[$gi] -= $sorted[$bi]->cask_width * ( 1 + $margin );
                $assign[$bi]  = DECK_IDX;
            }
        }
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

Runs a simulated annealer over two move types:

=over 4

=item * B<Swap moves> - two casks exchange slot groups (or one may be
on the deck).  This is the original move type.

=item * B<Relocation moves> - a single cask moves to a different slot
group (or to/from the deck) without a swap partner, chosen with
probability C<relocation_probability> (see
L<BeerFestDB::StillagePlanner::Config/relocation_probability>).

=back

For both move types, the first cask is usually *not* chosen uniformly
at random: with probability C<bias_probability> (see
L<BeerFestDB::StillagePlanner::Config/bias_probability>) it is instead
drawn from the current set of "offending" casks - those on the deck,
or belonging to a beer currently split across bays or stillages - so
that the search spends most of its effort repairing known problems
rather than testing arbitrary, likely-neutral swaps.

Only moves that satisfy the physical width constraints of the affected
slot group(s) are considered.  Worse moves may still be accepted
probabilistically according to the current temperature.  The best
assignment seen during the run is retained and returned.

If C<consolidation_interval> is configured, a deterministic
beer-consolidation pass (see L</_consolidate_split_beers>) runs every
that many iterations, attempting to move all casks of a split beer
onto whichever stillage already holds most of them; it is kept only if
it improves the current score.

Stops when the C<convergence_streak> threshold is reached after the
temperature has cooled to the floor, or when C<max_iterations> have
been attempted.

Returns the best total score seen.

=cut

sub plan {
    my ($self) = @_;

    croak 'Call initialise() before plan()'
        unless @{ $self->_assignment };

    croak 'initial_temperature must be non-zero (negative selects pure hill-climbing)'
        if $self->config->initial_temperature == 0;
    croak 'cooling_rate must be in the range (0, 1]'
        if $self->config->cooling_rate <= 0 || $self->config->cooling_rate > 1;
    croak 'temperature_floor must be positive'
        if $self->config->temperature_floor <= 0;

    my $casks     = $self->_cask_entries;
    my $groups    = $self->_slot_groups;
    my $n_casks   = scalar @$casks;
    my $n_groups  = scalar @$groups;
    my $margin    = $self->config->margin;

    my @assign    = @{ $self->_assignment };
    my @used_w    = @{ $self->_used_width };
    my @best_assign = @assign;
    my @best_used_w = @used_w;

    my $cur_score       = $self->_score_assignment( \@assign, \@used_w );
    my $best_score      = $cur_score;
    my $best_no_improv   = 0;
    my $temperature     = $self->config->initial_temperature;
    my $temperature_low = $self->config->temperature_floor;

    my $bias_prob          = $self->config->bias_probability;
    my $relocation_prob    = $self->config->relocation_probability;
    my $consolidate_every  = $self->config->consolidation_interval;

  ITER: for my $iter ( 1 .. $self->max_iterations ) {

        if ( $consolidate_every && $iter % $consolidate_every == 0 ) {
            if ( $self->_consolidate_split_beers( \@assign, \@used_w, \$cur_score ) ) {
                if ( $cur_score < $best_score ) {
                    $best_score  = $cur_score;
                    @best_assign = @assign;
                    @best_used_w = @used_w;
                    $best_no_improv = 0;
                }
            }
        }

        my $offenders = _offender_indices( $casks, $groups, \@assign );

        my $new_score = $cur_score;
        my ( $i, $j, $gi, $gj, $move_type );

        if ( rand() < $relocation_prob ) {
            ( $new_score, $i, $gi, $gj, $move_type ) = $self->_try_relocation_move(
                $casks, $groups, \@assign, \@used_w, $margin,
                $n_casks, $n_groups, $offenders, $bias_prob,
                $cur_score, $temperature,
            );
            $j = $i;
        }
        else {
            ( $new_score, $i, $j, $gi, $gj, $move_type ) = $self->_try_swap_move(
                $casks, $groups, \@assign, \@used_w, $margin,
                $n_casks, $offenders, $bias_prob,
                $cur_score, $temperature,
            );
        }

        if ( defined $move_type ) {
            $cur_score = $new_score;

            if ( $new_score < $best_score ) {
                $best_score  = $new_score;
                @best_assign = @assign;
                @best_used_w = @used_w;
                $best_no_improv = 0;
            }
            elsif ( $temperature <= $temperature_low ) {
                ++$best_no_improv;
            }

            if ( my $fh = $self->trace_filehandle ) {
                printf $fh "%d,%.1f,%.1f,%.1f,%.1f,%d,%d,%d,%d,%s\n",
                    $iter, $temperature, $best_score, $cur_score, $new_score,
                    $i, $j, $gi, $gj, $move_type;
            }
        }

        if ( $temperature >= 0 ) {
            # Simulated annealing: cool the temperature and stop if cooled to floor
            # with no improvement for convergence_streak iterations
            $temperature *= $self->config->cooling_rate;
            $temperature = $temperature_low if $temperature < $temperature_low;
            last ITER
                if $temperature <= $temperature_low
                && $best_no_improv >= $self->convergence_streak;
        } else {
            # Pure hill-climbing: stop if no improvement for convergence_streak iterations
            last ITER
                if $best_no_improv >= $self->convergence_streak;
        }
    }

    $self->_assignment( \@best_assign );
    $self->_used_width( \@best_used_w );
    return $best_score;
}

sub _acceptance_probability {
    my ( $delta, $temperature ) = @_;

    return 1 if $delta <= 0;
    return 0 if !defined $temperature || $temperature <= 0;

    return exp( -$delta / $temperature );
}

# Attempts a two-cask swap move, mutating $assign/$used_w in place and
# reverting them if the move is rejected.  Returns
# ( resulting_score, i, j, gi, gj, move_type ) where move_type is
# undef if no move was attempted (same group, or capacity exceeded).
sub _try_swap_move {
    my ( $self, $casks, $groups, $assign, $used_w, $margin,
         $n_casks, $offenders, $bias_prob, $cur_score, $temperature ) = @_;

    my ( $i, $j ) = _choose_pair(
        $n_casks, $self->config->max_swap_distance, $offenders, $bias_prob,
    );
    my $gi = $assign->[$i];
    my $gj = $assign->[$j];

    return ( $cur_score, $i, $j, $gi, $gj, undef ) if $gi == $gj;

    my $wi = $casks->[$i]->cask_width * ( 1 + $margin );
    my $wj = $casks->[$j]->cask_width * ( 1 + $margin );

    my $fits = 1;
    if ( $gi != DECK_IDX ) {
        my $new_w = $used_w->[$gi] - $wi + $wj;
        $fits = 0 if $new_w > $groups->[$gi]->width + 1e-9;
    }
    if ( $fits && $gj != DECK_IDX ) {
        my $new_w = $used_w->[$gj] - $wj + $wi;
        $fits = 0 if $new_w > $groups->[$gj]->width + 1e-9;
    }

    return ( $cur_score, $i, $j, $gi, $gj, undef ) unless $fits;

    @{$assign}[ $i, $j ] = @{$assign}[ $j, $i ];
    $used_w->[$gi] += $wj - $wi if $gi != DECK_IDX;
    $used_w->[$gj] += $wi - $wj if $gj != DECK_IDX;

    my $new_score = $self->_score_assignment( $assign, $used_w );

    if ( rand() < _acceptance_probability( $new_score - $cur_score, $temperature ) ) {
        return ( $new_score, $i, $j, $gi, $gj, 'S' );
    }

    @{$assign}[ $i, $j ] = @{$assign}[ $j, $i ];
    $used_w->[$gi] += $wi - $wj if $gi != DECK_IDX;
    $used_w->[$gj] += $wj - $wi if $gj != DECK_IDX;

    return ( $cur_score, $i, $j, $gi, $gj, 'S' );
}

# Attempts a single-cask relocation move (to a different slot group or
# the deck), mutating $assign/$used_w in place and reverting them if
# the move is rejected.  Returns ( resulting_score, i, gi, target,
# move_type ) where move_type is undef if the target has no capacity.
sub _try_relocation_move {
    my ( $self, $casks, $groups, $assign, $used_w, $margin,
         $n_casks, $n_groups, $offenders, $bias_prob, $cur_score, $temperature ) = @_;

    my $i      = _choose_index( $n_casks, $offenders, $bias_prob );
    my $gi     = $assign->[$i];
    my $target = _random_target_group( $n_groups, $gi );

    my $wi = $casks->[$i]->cask_width * ( 1 + $margin );

    if ( $target != DECK_IDX ) {
        my $new_w = $used_w->[$target] + $wi;
        return ( $cur_score, $i, $gi, $target, undef )
            if $new_w > $groups->[$target]->width + 1e-9;
    }

    $assign->[$i] = $target;
    $used_w->[$gi]     -= $wi if $gi     != DECK_IDX;
    $used_w->[$target] += $wi if $target != DECK_IDX;

    my $new_score = $self->_score_assignment( $assign, $used_w );

    if ( rand() < _acceptance_probability( $new_score - $cur_score, $temperature ) ) {
        return ( $new_score, $i, $gi, $target, 'R' );
    }

    $assign->[$i] = $gi;
    $used_w->[$gi]     += $wi if $gi     != DECK_IDX;
    $used_w->[$target] -= $wi if $target != DECK_IDX;

    return ( $cur_score, $i, $gi, $target, 'R' );
}

=head2 _consolidate_split_beers

Deterministic repair pass invoked periodically from L</plan> (see
C<consolidation_interval>).  For every beer currently split across
more than one stillage, relocates its casks from minority stillages
onto whichever slot groups have spare capacity on the majority
stillage.  The change is kept only if it strictly improves
C<$$cur_score_ref>; otherwise all relocations are reverted.

Mutates C<$assign> and C<$used_w> in place.  Returns true if the
change was kept.

=cut

sub _consolidate_split_beers {
    my ( $self, $assign, $used_w, $cur_score_ref ) = @_;

    my $casks  = $self->_cask_entries;
    my $groups = $self->_slot_groups;
    my $margin = $self->config->margin;

    my %stillage_counts;
    for my $ci ( 0 .. $#$assign ) {
        my $gi = $assign->[$ci];
        next if $gi == DECK_IDX;
        my $prod_id = $casks->[$ci]->product_group_id;
        my $sl_id   = $groups->[$gi]->stillage_location
            ->get_column('stillage_location_id');
        $stillage_counts{$prod_id}{$sl_id}++;
    }

    my @changes;    # [ cask_index, previous_group_index ]

    for my $prod_id ( keys %stillage_counts ) {
        my $counts = $stillage_counts{$prod_id};
        next if scalar( keys %$counts ) <= 1;    # not split

        my ($target_sl_id) = sort { $counts->{$b} <=> $counts->{$a} } keys %$counts;

        for my $ci ( 0 .. $#$assign ) {
            next unless $casks->[$ci]->product_group_id == $prod_id;
            my $gi = $assign->[$ci];
            next if $gi == DECK_IDX;
            next if $groups->[$gi]->stillage_location
                ->get_column('stillage_location_id') == $target_sl_id;

            my $new_gi;
            for my $gj ( 0 .. $#$groups ) {
                next unless $groups->[$gj]->stillage_location
                    ->get_column('stillage_location_id') == $target_sl_id;
                if ( $groups->[$gj]->can_fit( $used_w->[$gj], $casks->[$ci]->cask_width ) ) {
                    $new_gi = $gj;
                    last;
                }
            }
            next unless defined $new_gi;

            my $wi = $casks->[$ci]->cask_width * ( 1 + $margin );
            $used_w->[$gi]     -= $wi;
            $used_w->[$new_gi] += $wi;
            $assign->[$ci] = $new_gi;
            push @changes, [ $ci, $gi ];
        }
    }

    return 0 unless @changes;

    my $new_score = $self->_score_assignment( $assign, $used_w );

    if ( $new_score < $$cur_score_ref ) {
        $$cur_score_ref = $new_score;
        return 1;
    }

    for my $change ( reverse @changes ) {
        my ( $ci, $old_gi ) = @$change;
        my $cur_gi = $assign->[$ci];
        my $wi     = $casks->[$ci]->cask_width * ( 1 + $margin );
        $used_w->[$cur_gi] -= $wi;
        $used_w->[$old_gi] += $wi;
        $assign->[$ci] = $old_gi;
    }

    return 0;
}

=head2 apply

Writes the current planned assignment back to the database inside a
single transaction.

For on-stillage casks, sets C<stillage_location_id>, C<stillage_bay>,
and C<bay_position_id>.

For deck casks, NULLs all three location fields.

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
                        }
                    );
                }
                else {
                    $cm->update(
                        {
                            stillage_location_id => undef,
                            stillage_bay         => undef,
                            bay_position_id      => undef,
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
    my $w_stillage = $config->weight( 'stillage',         1000 );
    my $w_pullthru = $config->weight( 'pull_through',       15 );
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

    # ── 3. Beer on same stillage ───────────────────────────────────────────
    # Penalty per extra distinct stillage pair a beer occupies. This is a much
    # higher penalty than the proximity penalty, to encourage beers to be on the
    # same stillage if possible.
    my %stillages;
    for my $ci ( 0 .. $#$casks ) {
        my $gi = $assign->[$ci];
        next if $gi == DECK_IDX;
        my $stillage_loc = $groups->[$gi]->stillage_location->description;
        $stillages{ $casks->[$ci]->product_group_id }{$stillage_loc} = 1;
    }
    for my $prod_id ( keys %stillages ) {
        my $n = scalar keys %{ $stillages{$prod_id} };
        $score += ( $n - 1 ) * $w_stillage if $n > 1;
    }

    # ── 4. Deck placement ─────────────────────────────────────────────────
    for my $ci ( 0 .. $#$casks ) {
        next if $assign->[$ci] != DECK_IDX;
        my $e          = $casks->[$ci];
        my $importance = $e->cask_count + 1 - $e->cask_number;
        my $penalty    = $importance * $w_deck;
        $penalty *= $sor_mult if $e->is_sale_or_return;
        $score += $penalty;
    }

    # ── 5. Pull-through placement ─────────────────────────────────────────
    # We assume the first word of the bay position description relates to the
    # stillage level, e.g. "Top" or "Bottom". We penalise bays where there is
    # beer assignment mismatch within the levels (e.g. Top Front and Top Rear),
    # to encourage assignments where beers are stillaged one in front of
    # another for pull-through.
    my %pullthroughs;
    for my $ci ( 0 .. $#$casks ) {
        my $gi = $assign->[$ci];
        next if $gi == DECK_IDX;
        my $bay_id = $groups->[$gi]->bay_id;
        my ($level, $depth) = ( $groups->[$gi]->bay_position->description =~ /\A (\S+) \s+ (.+)/xms );
        $pullthroughs{ $bay_id }{ $level }{ $depth }{ $casks->[$ci]->product_group_id }++;
    }
    while (my ($bay_id, $bayhash) = each %pullthroughs ) {
        while (my ($level, $lvlhash) = each %$bayhash ) {
            # Each depth now represented by a hash of product_group_id => count. We want to
            # check that all depths have the same product_group_id => count mapping, i.e.
            # the same beers are assigned at each depth (pull-through alignment).
            my @depth_hashes = values %$lvlhash;
            if ( @depth_hashes > 1 ) {
                my $ref      = $depth_hashes[0];
                my @ref_keys = sort keys %$ref;
                my $all_same = 1;
                for my $h ( @depth_hashes[ 1 .. $#depth_hashes ] ) {
                    my @h_keys = sort keys %$h;
                    if ( "@ref_keys" ne "@h_keys" ) {
                        $all_same = 0;
                        last;
                    }
                    for my $k ( @ref_keys ) {
                        if ( $ref->{$k} != $h->{$k} ) {
                            $all_same = 0;
                            last;
                        }
                    }
                    last unless $all_same;
                }
                $score += $w_pullthru unless $all_same;
            }
        }
    }

    return $score;
}

# Returns an arrayref of cask indices that are currently "offending":
# on the deck, or belonging to a beer split across bays or stillages.
# Used to bias move selection towards casks worth fixing.
sub _offender_indices {
    my ( $casks, $groups, $assign ) = @_;

    my ( %bay_of_product, %stillage_of_product );
    for my $ci ( 0 .. $#$assign ) {
        my $gi = $assign->[$ci];
        next if $gi == DECK_IDX;
        my $prod_id = $casks->[$ci]->product_group_id;
        $bay_of_product{$prod_id}{ $groups->[$gi]->bay_id } = 1;
        $stillage_of_product{$prod_id}{
            $groups->[$gi]->stillage_location->get_column('stillage_location_id')
        } = 1;
    }

    my @offenders;
    for my $ci ( 0 .. $#$assign ) {
        my $gi = $assign->[$ci];
        if ( $gi == DECK_IDX ) {
            push @offenders, $ci;
            next;
        }
        my $prod_id = $casks->[$ci]->product_group_id;
        push @offenders, $ci
            if scalar( keys %{ $bay_of_product{$prod_id} } ) > 1
            || scalar( keys %{ $stillage_of_product{$prod_id} } ) > 1;
    }

    return \@offenders;
}

# Returns a single cask index, drawn from @$offenders with probability
# $bias_prob (if any offenders exist), otherwise uniformly from [0, $n-1].
sub _choose_index {
    my ( $n, $offenders, $bias_prob ) = @_;
    if ( @$offenders && rand() < $bias_prob ) {
        return $offenders->[ int( rand( scalar @$offenders ) ) ];
    }
    return int( rand($n) );
}

# Returns two distinct cask indices ($i, $j).  $i is chosen via
# _choose_index (biased towards @$offenders); $j is a uniformly random
# partner, restricted to |i - j| <= $max_dist if defined.
sub _choose_pair {
    my ( $n, $max_dist, $offenders, $bias_prob ) = @_;
    my $i = _choose_index( $n, $offenders, $bias_prob );
    my $j;
    if ( defined $max_dist && $max_dist > 0 ) {
        my $lo = ( $i - $max_dist ) < 0     ? 0      : $i - $max_dist;
        my $hi = ( $i + $max_dist ) >= $n   ? $n - 1 : $i + $max_dist;
        my $range = $hi - $lo;       # number of candidates excluding $i itself
        # Avoid infinite loop when $i is the only index in range
        return ( $i, $i ) if $range == 0;
        do { $j = $lo + int( rand( $range + 1 ) ) } while $j == $i;
    }
    else {
        do { $j = int( rand($n) ) } while $j == $i;
    }
    return ( $i, $j );
}

# Returns a slot group index different from $exclude_gi, or DECK_IDX,
# as the target of a relocation move.  The deck is offered with
# probability 1/($n_groups+1); otherwise a slot group is chosen
# uniformly at random.
sub _random_target_group {
    my ( $n_groups, $exclude_gi ) = @_;
    my $target;
    do {
        $target = ( rand() < 1 / ( $n_groups + 1 ) )
            ? DECK_IDX
            : int( rand($n_groups) );
    } while ( $target == $exclude_gi );
    return $target;
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

=item B<Beer on same stillage> (default weight 1000)

For each beer with multiple on-stillage casks, the penalty is
C<(number of distinct stillages - 1) x weight>.  This encourages all
casks of the same beer to land on the same stillage (and therefore be
managed by the same cellar team).

=item B<Deck placement> (default weight 20; SOR multiplier 0.1)

Each deck cask receives
C<(cask_count + 1 - cask_number) x weight x (SOR_multiplier if SOR)>
as a penalty.  The first cask of a beer is penalised most; the last
least.  Sale-or-return casks receive a much smaller penalty.

=item B<Pull-through placement> (default weight 15)

For each bay, the casks are grouped by stillage level (e.g. Top or 
Bottom).  Within each level, the casks are grouped by depth (e.g.
Front or Rear).  If the product assignments differ between depths,
a penalty of C<weight> is added.  This encourages casks of the same
beer to be aligned front-to-back for pull-through dispensing.

=back

=head1 ALGORITHM

Starting from a greedy alphabetical first-fit initial assignment,
L</plan> applies a simulated annealer with two move types, swap and
relocation, biased towards casks that are currently causing penalty:

=over 4

=item 1. On each iteration, with probability C<relocation_probability>
a single-cask relocation move is attempted; otherwise a two-cask swap
is attempted.

=item 2. The first cask involved is usually not chosen uniformly at
random: with probability C<bias_probability> it is instead drawn from
the current set of "offending" casks (on the deck, or belonging to a
beer split across bays or stillages), so the search concentrates on
fixing known problems rather than testing arbitrary moves.  The
remaining cask (swap partner, or relocation target slot group/deck) is
chosen at random.

=item 3. If the move would overfill any affected slot group (width
constraint), it is immediately rejected.

=item 4. Otherwise the new score is computed.  If it improved, the move
is kept.  If it worsened, it may still be kept with a probability that
decreases as the temperature cools; otherwise it is reverted.

=item 5. The temperature is cooled after each iteration.  After the
search has cooled to the floor and C<convergence_streak> consecutive
iterations have failed to improve the best score, or after
C<max_iterations> attempts, the loop terminates.

=item 6. If C<consolidation_interval> is set, every that many
iterations a deterministic pass tries to move each split beer's casks
onto whichever stillage already holds most of them, keeping the change
only if it improves the score.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

