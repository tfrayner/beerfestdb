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

our $VERSION = '0.01';

=head1 NAME

BeerFestDB::StillagePlanner - Automated placement of casks on a stillage

=head1 SYNOPSIS

  use BeerFestDB::ORM;
  use BeerFestDB::StillagePlanner;

  my $schema   = BeerFestDB::ORM->connect($dsn);
  my $stillage = $schema->resultset('StillageLocation')->find(1);

  my $planner = BeerFestDB::StillagePlanner->new(
      database          => $schema,
      stillage_location => $stillage,
      num_bays          => 20,
      bay_capacity      => 2,
  );

  my $n = $planner->load_casks();
  $planner->initialise();
  my $score = $planner->plan();
  print $planner->render();
  $planner->apply();   # writes stillage_bay / stillage_x_location back to DB

=head1 DESCRIPTION

C<BeerFestDB::StillagePlanner> attempts to find a good arrangement of
casks along a named stillage, minimising a configurable penalty score
that accounts for:

=over 4

=item * B<Alphabetical order> – casks should be ordered by brewery then
beer name along the stillage.

=item * B<Beer proximity> – multiple casks of the same beer should be
placed together without gaps.

=item * B<Deck placement> – when there are more casks than stillage slots,
some casks go on the deck (floor).  The penalty is higher for lower
cask numbers (cask 1 of a beer should never be on the deck) and much
lower for sale-or-return casks.

=back

The algorithm is a random-pair-swap hill-climber with cycle detection.
Starting from an alphabetically sorted initial layout, it repeatedly
tries swapping two randomly chosen slots, keeping the swap when it
reduces the total penalty.  Iteration stops when a convergence streak
limit or maximum iteration count is reached, or when a previously seen
layout state is encountered.

=head1 ATTRIBUTES

=head2 database

A connected L<DBIx::Class::Schema> instance (typically
L<BeerFestDB::ORM>).  Required.

=cut

has 'database' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

=head2 stillage_location

A L<BeerFestDB::ORM::StillageLocation> row identifying the stillage to
plan.  Required.

=cut

has 'stillage_location' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 num_bays

Number of bays along the stillage.  Required.

=cut

has 'num_bays' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=head2 bay_capacity

Maximum number of cask positions per bay (default 1).  The total
number of on-stillage positions is C<num_bays * bay_capacity>.

=cut

has 'bay_capacity' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
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

Stop if this many consecutive swap attempts produce no improvement
(default 500).

=cut

has 'convergence_streak' => (
    is      => 'ro',
    isa     => 'Int',
    default => 500,
);

=head2 weight_alphabetical

Penalty added per adjacent out-of-order pair on the stillage
(default 10).

=cut

has 'weight_alphabetical' => (
    is      => 'ro',
    isa     => 'Num',
    default => 10,
);

=head2 weight_proximity

Penalty added per slot of separation between same-beer casks on the
stillage (default 5).

=cut

has 'weight_proximity' => (
    is      => 'ro',
    isa     => 'Num',
    default => 5,
);

=head2 weight_deck

Base per-importance-point penalty for placing a cask on the deck
(default 20).  The importance of a deck placement is
C<cask_count + 1 - cask_number>, so earlier casks are penalised more
heavily.

=cut

has 'weight_deck' => (
    is      => 'ro',
    isa     => 'Num',
    default => 20,
);

=head2 weight_sor_deck_multiplier

Multiplier applied to the deck penalty for sale-or-return casks
(default 0.1).

=cut

has 'weight_sor_deck_multiplier' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.1,
);

# ── Internal state ────────────────────────────────────────────────────────────

has '_cask_entries' => (
    is      => 'rw',
    isa     => 'ArrayRef[BeerFestDB::StillagePlanner::CaskEntry]',
    default => sub { [] },
);

# _layout is an array-ref of (CaskEntry | undef):
#   indices 0 .. num_positions-1  => on the stillage
#   indices num_positions .. $#   => on the deck
has '_layout' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

# ── Derived ───────────────────────────────────────────────────────────────────

=head1 METHODS

=head2 num_positions

Returns C<num_bays * bay_capacity>: the total number of cask slots
available on the stillage.

=cut

sub num_positions {
    my ($self) = @_;
    return $self->num_bays * $self->bay_capacity;
}

# ── Public interface ──────────────────────────────────────────────────────────

=head2 load_casks

Loads all active (non-graveyarded, non-condemned) cask management rows
for the planner's C<stillage_location> from the database.  For each
row the brewery name, beer name and container type are resolved via the
ORM.  Cask numbers within each beer are assigned in ascending
C<cellar_reference> order.

Returns the number of cask entries loaded.

=cut

sub load_casks {
    my ($self) = @_;

    my $db    = $self->database;
    my $sl_id = $self->stillage_location->get_column('stillage_location_id');

    my @caskmans = $db->resultset('CaskManagement')->search(
        {
            stillage_location_id => $sl_id,
            cask_graveyard       => undef,
        },
    )->all;

    my @entries;
    for my $cm (@caskmans) {

        # Walk: cask_management → casks → gyle → festival_product → product → company
        # (In this ORM, belongs_to accessors carry the column name and return the
        # related object, not the raw integer.)
        my ($cask) = $cm->casks->search(
            { is_condemned => [ 0, undef ] } )->all;
        next unless defined $cask;

        my $gyle    = $cask->gyle_id;
        my $fp      = $gyle->festival_product_id;
        my $product = $fp->product_id;
        my $company = $product->company_id;

        my $beer_name    = $product->name;
        my $brewery_name = $company->name;
        my $fp_id        = $fp->get_column('festival_product_id');
        my $sort_key     = lc("$brewery_name $beer_name");

        my $container_type = $cm->container_size_id->description;

        push @entries, BeerFestDB::StillagePlanner::CaskEntry->new(
            cask_management     => $cm,
            beer_name           => $beer_name,
            brewery_name        => $brewery_name,
            sort_key            => $sort_key,
            cask_number         => 1,      # placeholder, corrected below
            cask_count          => 1,      # placeholder, corrected below
            is_sale_or_return   => ($cm->is_sale_or_return // 0) ? 1 : 0,
            container_type      => $container_type,
            festival_product_id => $fp_id,
        );
    }

    # Number casks within each beer by ascending cellar_reference
    my %by_fp;
    for my $entry (@entries) {
        push @{ $by_fp{ $entry->festival_product_id } }, $entry;
    }

    for my $fp_id ( sort keys %by_fp ) {
        my @beer_casks = sort {
            $a->cask_management->cellar_reference
                <=> $b->cask_management->cellar_reference
        } @{ $by_fp{$fp_id} };

        my $count = scalar @beer_casks;
        for my $i ( 0 .. $#beer_casks ) {
            $beer_casks[$i]->cask_number( $i + 1 );
            $beer_casks[$i]->cask_count($count);
        }
    }

    $self->_cask_entries( \@entries );
    return scalar @entries;
}

=head2 initialise

Builds the initial layout by sorting all loaded cask entries
alphabetically (by C<sort_key>, then C<cask_number>), placing them
into stillage slots 0 .. N-1 in order.  Any casks beyond
C<num_positions> are appended as deck entries.

Must be called after L</load_casks>.

=cut

sub initialise {
    my ($self) = @_;

    my @sorted = sort {
            $a->sort_key    cmp $b->sort_key
        ||  $a->cask_number <=> $b->cask_number
    } @{ $self->_cask_entries };

    my $num_pos = $self->num_positions;
    my @layout;

    # Fill stillage slots
    for my $i ( 0 .. $num_pos - 1 ) {
        $layout[$i] = $sorted[$i];    # may be undef if fewer casks than slots
    }

    # Append any overflow casks as deck entries
    for my $i ( $num_pos .. $#sorted ) {
        push @layout, $sorted[$i];
    }

    $self->_layout( \@layout );
    return;
}

=head2 score

Returns the total penalty score for the current layout.  Lower is better.
See L</DESCRIPTION> for the scoring components.

=cut

sub score {
    my ($self) = @_;
    return $self->_score_layout( $self->_layout );
}

=head2 plan

Runs the iterative random-swap hill-climber.

At each step two slots are chosen at random; if swapping them reduces
the total score the swap is kept, otherwise it is reversed.  The
method stops when:

=over 4

=item * C<convergence_streak> consecutive non-improving iterations occur, or

=item * C<max_iterations> have been attempted, or

=item * a previously seen layout state is encountered (cycle detection).

=back

Returns the final total score.

=cut

sub plan {
    my ($self) = @_;

    croak 'Call load_casks() and initialise() before plan()'
        unless @{ $self->_layout };

    my $layout        = $self->_layout;
    my $n             = scalar @$layout;
    my $current_score = $self->_score_layout($layout);
    my $no_improve    = 0;
    my %seen          = ( $self->_state_string($layout) => 1 );

    for my $iter ( 1 .. $self->max_iterations ) {

        my ( $i, $j ) = _random_pair($n);

        # Tentative swap
        @{$layout}[ $i, $j ] = @{$layout}[ $j, $i ];

        my $new_score = $self->_score_layout($layout);

        if ( $new_score < $current_score ) {
            $current_score = $new_score;
            $no_improve    = 0;

            my $state = $self->_state_string($layout);
            if ( $seen{$state} ) {
                # Cycle detected – revert and stop
                @{$layout}[ $i, $j ] = @{$layout}[ $j, $i ];
                last;
            }
            $seen{$state} = 1;
        }
        else {
            # Revert
            @{$layout}[ $i, $j ] = @{$layout}[ $j, $i ];
            last if ++$no_improve >= $self->convergence_streak;
        }
    }

    $self->_layout($layout);
    return $current_score;
}

=head2 apply

Writes the current planned layout back to the database.

For casks on the stillage, C<stillage_bay> (1-based bay number) and
C<stillage_x_location> (1-based absolute slot index) are updated and
C<cask_graveyard> is cleared.

For casks on the deck, C<stillage_bay> and C<stillage_x_location> are
set to C<NULL> and C<cask_graveyard> is set to C<"deck">.

All updates run inside a single database transaction.

=cut

sub apply {
    my ($self) = @_;

    my $db      = $self->database;
    my $layout  = $self->_layout;
    my $num_pos = $self->num_positions;

    $db->txn_do(
        sub {
            for my $slot ( 0 .. $#$layout ) {
                my $entry = $layout->[$slot];
                next unless defined $entry;

                my $cm = $entry->cask_management;

                if ( $slot < $num_pos ) {
                    my $bay = int( $slot / $self->bay_capacity ) + 1;  # 1-based
                    my $x   = $slot + 1;                               # 1-based

                    $cm->update(
                        {
                            stillage_bay        => $bay,
                            stillage_x_location => $x,
                            cask_graveyard      => undef,
                        }
                    );
                }
                else {
                    $cm->update(
                        {
                            stillage_bay        => undef,
                            stillage_x_location => undef,
                            cask_graveyard      => 'deck',
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
layout, one slot per line, suitable for review before committing to
the database.

=cut

sub render {
    my ($self) = @_;

    my $layout  = $self->_layout;
    my $num_pos = $self->num_positions;
    my @lines;

    push @lines, sprintf(
        "Stillage: %s  (%d bay%s x %d position%s per bay = %d slots)",
        $self->stillage_location->description,
        $self->num_bays,
        $self->num_bays == 1 ? '' : 's',
        $self->bay_capacity,
        $self->bay_capacity == 1 ? '' : 's',
        $num_pos,
    );
    push @lines, sprintf( "Score: %.1f", $self->score );
    push @lines, '';

    my $on_deck = 0;
    for my $slot ( 0 .. $#$layout ) {

        if ( $slot == $num_pos && !$on_deck ) {
            push @lines, '--- DECK ---';
            $on_deck = 1;
        }

        my $entry   = $layout->[$slot];
        my $loc_str = $slot < $num_pos
            ? sprintf( 'Bay %3d', int( $slot / $self->bay_capacity ) + 1 )
            : 'Deck   ';

        if ( defined $entry ) {
            push @lines, sprintf( "  [%3d] %s  %s",
                $slot + 1, $loc_str, $entry->label );
        }
        else {
            push @lines, sprintf( "  [%3d] %s  (empty)", $slot + 1, $loc_str );
        }
    }

    return join( "\n", @lines ) . "\n";
}

# ── Private helpers ───────────────────────────────────────────────────────────

sub _score_layout {
    my ( $self, $layout ) = @_;

    my $num_pos  = $self->num_positions;
    my $w_alpha  = $self->weight_alphabetical;
    my $w_prox   = $self->weight_proximity;
    my $w_deck   = $self->weight_deck;
    my $sor_mult = $self->weight_sor_deck_multiplier;

    my $score = 0;

    # ── 1. Alphabetical order (non-empty slots only, maintaining order) ───
    my @occupied = grep { defined $_ } @{$layout}[ 0 .. $num_pos - 1 ];
    for my $i ( 0 .. $#occupied - 1 ) {
        $score += $w_alpha
            if $occupied[$i]->sort_key gt $occupied[ $i + 1 ]->sort_key;
    }

    # ── 2. Proximity: same-beer casks should be adjacent ─────────────────
    my %positions;
    for my $i ( 0 .. $num_pos - 1 ) {
        my $e = $layout->[$i];
        next unless defined $e;
        push @{ $positions{ $e->festival_product_id } }, $i;
    }
    for my $fp_id ( keys %positions ) {
        my @pos = sort { $a <=> $b } @{ $positions{$fp_id} };
        for my $j ( 0 .. $#pos - 1 ) {
            my $gap = $pos[ $j + 1 ] - $pos[$j] - 1;
            $score += $gap * $w_prox if $gap > 0;
        }
    }

    # ── 3. Deck placement penalty ─────────────────────────────────────────
    my $n = scalar @$layout;
    for my $i ( $num_pos .. $n - 1 ) {
        my $e = $layout->[$i];
        next unless defined $e;
        my $importance   = $e->cask_count + 1 - $e->cask_number;
        my $base_penalty = $importance * $w_deck;
        $base_penalty *= $sor_mult if $e->is_sale_or_return;
        $score += $base_penalty;
    }

    return $score;
}

# Compact fingerprint of the layout for cycle detection.
sub _state_string {
    my ( $self, $layout ) = @_;
    my @ids = map {
        defined $_ ? $_->cask_management->get_column('cask_management_id') : 0
    } @$layout;
    return md5_hex( join( ',', @ids ) );
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

The penalty score is the sum of three components:

=over 4

=item B<Alphabetical order> (C<weight_alphabetical>, default 10)

The occupied stillage slots are scanned left-to-right.  Each adjacent
pair that is out of alphabetical order (by C<sort_key>) adds one unit
of this weight to the score.  Empty slots are ignored.

=item B<Beer proximity> (C<weight_proximity>, default 5)

For each beer with multiple casks on the stillage, the slots occupied
by that beer are sorted.  Each slot of gap between consecutive same-beer
casks adds one unit of this weight to the score.

=item B<Deck penalty> (C<weight_deck>, default 20; modulated by
C<weight_sor_deck_multiplier>, default 0.1)

A cask sent to the deck receives a penalty of
C<(cask_count + 1 - cask_number) * weight_deck>.  This means the first
cask of a beer is penalised most (it should always be on the stillage)
and the last cask least.  The entire penalty is multiplied by
C<weight_sor_deck_multiplier> for sale-or-return casks.

=back

=head1 ALGORITHM

Starting from an alphabetically sorted initial layout,
L</plan> applies a random-pair-swap hill-climber:

=over 4

=item 1. Two slots are chosen uniformly at random.

=item 2. Their contents are swapped and the new score computed.

=item 3. If the score improved the swap is kept; otherwise it is reverted.

=item 4. After C<convergence_streak> (default 500) consecutive
non-improving swaps, or after C<max_iterations> (default 5000)
attempts, or upon cycle detection, the loop terminates.

=back

Because the algorithm is stochastic, repeated runs may produce
slightly different results.  For reproducibility, set C<srand> before
calling L</plan>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

