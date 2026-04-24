#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
#
# Copyright (C) 2026 Tim F. Rayner
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

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Scalar::Util qw(looks_like_number);

use BeerFestDB::ORM;
use BeerFestDB::Web;
use BeerFestDB::StillagePlanner;

########################################################################
# Command-line arguments
########################################################################

my ( $want_help, $opt_apply, $opt_bays, $opt_capacity,
     $opt_max_iter, $opt_convergence, $opt_seed,
     $opt_w_alpha, $opt_w_prox, $opt_w_deck, $opt_w_sor );

GetOptions(
    'h|help'            => \$want_help,
    'apply'             => \$opt_apply,
    'bays=i'            => \$opt_bays,
    'capacity=i'        => \$opt_capacity,
    'max-iterations=i'  => \$opt_max_iter,
    'convergence=i'     => \$opt_convergence,
    'seed=i'            => \$opt_seed,
    'w-alpha=f'         => \$opt_w_alpha,
    'w-proximity=f'     => \$opt_w_prox,
    'w-deck=f'          => \$opt_w_deck,
    'w-sor=f'           => \$opt_w_sor,
) or pod2usage( -exitval => 1, -output => \*STDERR );

if ($want_help) {
    pod2usage(
        -exitval => 0,
        -output  => \*STDOUT,
        -verbose => 1,
    );
}

die("Error: --bays must be a positive integer.\n")
    if defined $opt_bays && ( !looks_like_number($opt_bays) || $opt_bays < 1 );

die("Error: --capacity must be a positive integer.\n")
    if defined $opt_capacity
        && ( !looks_like_number($opt_capacity) || $opt_capacity < 1 );

########################################################################
# Helper: interactive stillage selector
########################################################################

sub select_stillage {
    my ( $schema, $festival ) = @_;

    my @locs = $schema->resultset('StillageLocation')
        ->search( { festival_id => $festival->get_column('festival_id') },
                  { order_by    => 'description' } )
        ->all;

    die("Error: no stillage locations found for this festival.\n")
        unless @locs;

    return $locs[0] if @locs == 1;

    my $wanted;
    SELECT: {
        warn("Please select the stillage to plan:\n\n");
        for my $n ( 1 .. @locs ) {
            warn( sprintf( "  %d: %s\n", $n, $locs[$n-1]->description ) );
        }
        warn("\n");
        chomp( my $sel = <STDIN> );
        redo SELECT
            unless looks_like_number($sel) && ( $wanted = $locs[$sel-1] );
    }
    return $wanted;
}

########################################################################
# Helper: ask for an integer with a default
########################################################################

sub prompt_int {
    my ( $prompt, $default ) = @_;
    warn("$prompt [default: $default]: ");
    chomp( my $val = <STDIN> );
    $val = $default unless length $val;
    die("Error: '$val' is not a positive integer.\n")
        unless looks_like_number($val) && $val >= 1;
    return int($val);
}

########################################################################
# Main
########################################################################

my $config = BeerFestDB::Web->config();
my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

# ── Festival selection (reuses the MenuSelector logic inline) ──────────────

my $festival;
if ( my $festname = $config->{'current_festival'} ) {
    $festival = $schema->resultset('Festival')
        ->find({ name => $festname })
            or die(qq{Error: configured festival "$festname" not found.\n});
}
else {
    my @festivals = $schema->resultset('Festival')->all;
    die("Error: no festivals found in the database.\n") unless @festivals;

    if ( @festivals == 1 ) {
        $festival = $festivals[0];
    }
    else {
        my $wanted;
        SELECT_FEST: {
            warn("Please select the beer festival of interest:\n\n");
            for my $n ( 1 .. @festivals ) {
                my $f = $festivals[$n-1];
                warn( sprintf( "  %d: %d %s\n", $n, $f->year, $f->name ) );
            }
            warn("\n");
            chomp( my $sel = <STDIN> );
            redo SELECT_FEST
                unless looks_like_number($sel)
                    && ( $wanted = $festivals[$sel-1] );
        }
        $festival = $wanted;
    }
}

warn( sprintf( "Festival: %d %s\n\n", $festival->year, $festival->name ) );

# ── Stillage selection ────────────────────────────────────────────────────

my $stillage = select_stillage( $schema, $festival );
warn( sprintf( "Stillage: %s\n\n", $stillage->description ) );

# ── Stillage dimensions ───────────────────────────────────────────────────

my $num_bays    = $opt_bays     // prompt_int( 'Number of bays', 20 );
my $bay_cap     = $opt_capacity // prompt_int( 'Cask positions per bay', 1 );

# ── Build the planner ─────────────────────────────────────────────────────

my %planner_args = (
    database          => $schema,
    stillage_location => $stillage,
    num_bays          => $num_bays,
    bay_capacity      => $bay_cap,
);

$planner_args{max_iterations}    = $opt_max_iter    if defined $opt_max_iter;
$planner_args{convergence_streak} = $opt_convergence if defined $opt_convergence;
$planner_args{weight_alphabetical}        = $opt_w_alpha if defined $opt_w_alpha;
$planner_args{weight_proximity}           = $opt_w_prox  if defined $opt_w_prox;
$planner_args{weight_deck}                = $opt_w_deck  if defined $opt_w_deck;
$planner_args{weight_sor_deck_multiplier} = $opt_w_sor   if defined $opt_w_sor;

my $planner = BeerFestDB::StillagePlanner->new(%planner_args);

# ── Load and plan ─────────────────────────────────────────────────────────

srand($opt_seed) if defined $opt_seed;

my $n = $planner->load_casks();
warn("Loaded $n cask(s) from stillage '" . $stillage->description . "'.\n");

if ( $n == 0 ) {
    warn("Nothing to plan.\n");
    exit 0;
}

$planner->initialise();
warn( sprintf( "Initial score: %.1f\n", $planner->score ) );

my $final_score = $planner->plan();
warn( sprintf( "Final score:   %.1f\n\n", $final_score ) );

# ── Print layout ─────────────────────────────────────────────────────────

print $planner->render();

# ── Optionally write back to the database ────────────────────────────────

if ($opt_apply) {
    $planner->apply();
    warn("\nLayout written to the database.\n");
}
else {
    warn("\nRun with --apply to commit this layout to the database.\n");
}

exit 0;

__END__

=head1 NAME

plan_stillage.pl - Automatically arrange casks along a stillage

=head1 SYNOPSIS

 plan_stillage.pl [options]

 Options:
   --bays N            Number of bays on the stillage
   --capacity N        Cask positions per bay (default 1)
   --apply             Write the planned layout back to the database
   --max-iterations N  Maximum number of swap attempts (default 5000)
   --convergence N     Stop after N consecutive non-improving swaps (default 500)
   --seed N            Random seed for reproducibility
   --w-alpha F         Weight for alphabetical-order violations (default 10)
   --w-proximity F     Weight for same-beer separation (default 5)
   --w-deck F          Base weight for deck placement (default 20)
   --w-sor F           Deck-penalty multiplier for sale-or-return casks (default 0.1)
   -h, --help          Show this help message

=head1 DESCRIPTION

C<plan_stillage.pl> uses L<BeerFestDB::StillagePlanner> to find a
near-optimal arrangement of casks along a named stillage.

The script will prompt interactively for the festival and stillage
(unless C<current_festival> is set in the BeerFestDB configuration and
there is only one stillage for that festival).  The number of bays and
cask positions per bay must be supplied either on the command line or
interactively.

A dry-run layout is always printed to standard output.  Pass C<--apply>
to write the planned C<stillage_bay> and C<stillage_x_location> values
back to the C<cask_management> table (casks that overflow the available
slots are placed on the deck and have their C<cask_graveyard> set to
C<"deck">).

=head2 Scoring weights

The penalty function combines three components; each can be tuned with
the corresponding command-line option:

=over 4

=item C<--w-alpha>

Penalty added for each adjacent out-of-order pair on the stillage
(alphabetical ordering).

=item C<--w-proximity>

Penalty per slot of separation between same-beer casks.

=item C<--w-deck>

Base per-importance-point penalty for placing a cask on the deck.

=item C<--w-sor>

Multiplier applied to the deck penalty for sale-or-return casks
(default 0.1, making SOR placement nearly free).

=back

=head2 Reproducibility

Because the hill-climber uses random pair selection, different runs
may produce slightly different layouts.  Use C<--seed N> to fix the
random seed and obtain repeatable results.

=head1 SEE ALSO

L<BeerFestDB::StillagePlanner>, L<BeerFestDB::StillagePlanner::CaskEntry>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut
