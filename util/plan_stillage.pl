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
use BeerFestDB::StillagePlanner::Config;

########################################################################
# Command-line arguments
########################################################################

my ( $want_help, $opt_apply, $opt_config,
     $opt_max_iter, $opt_convergence, $opt_max_swap_distance, $opt_seed );

GetOptions(
    'h|help'            => \$want_help,
    'apply'             => \$opt_apply,
    'config=s'          => \$opt_config,
    'max-iterations=i'  => \$opt_max_iter,
    'convergence=i'     => \$opt_convergence,
    'max-swap-distance=i' => \$opt_max_swap_distance,
    'seed=i'            => \$opt_seed,
) or pod2usage( -exitval => 1, -output => \*STDERR );

if ($want_help) {
    pod2usage(
        -exitval => 0,
        -output  => \*STDOUT,
        -verbose => 1,
    );
}

die("Error: --config is required.\n")
    unless defined $opt_config;

die("Error: config file '$opt_config' not found.\n")
    unless -f $opt_config;

########################################################################
# Main
########################################################################

my $web_config = BeerFestDB::Web->config();
my $schema = BeerFestDB::ORM->connect( @{ $web_config->{'Model::DB'}{'connect_info'} } );

my $planner_config = BeerFestDB::StillagePlanner::Config->new(
    config_file => $opt_config,
);

# ── Build the planner ─────────────────────────────────────────────────────────

my %planner_args = (
    database => $schema,
    config   => $planner_config,
);

$planner_args{max_iterations}     = $opt_max_iter    if defined $opt_max_iter;
$planner_args{convergence_streak} = $opt_convergence if defined $opt_convergence;
$planner_args{max_swap_distance}  = $opt_max_swap_distance if defined $opt_max_swap_distance;

my $planner = BeerFestDB::StillagePlanner->new(%planner_args);

warn( sprintf( "Festival: %d %s\n\n", $planner->festival->year, $planner->festival->name ) );

# ── Load, build slots, and plan ───────────────────────────────────────────────

srand($opt_seed) if defined $opt_seed;

my $n_casks = $planner->load_casks();
warn("Loaded $n_casks unassigned cask(s) for this festival.\n");

if ( $n_casks == 0 ) {
    warn("Nothing to plan.\n");
    exit 0;
}

my $n_slots = $planner->build_slots();
warn("Planning into $n_slots slot group(s) from config.\n");

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

plan_stillage.pl - Automatically assign unplaced casks to stillage positions

=head1 SYNOPSIS

 plan_stillage.pl --config stillage_plan.yml [options]

 Required:
   --config FILE       Path to the YAML planning configuration file

 Options:
   --apply             Write the planned layout back to the database
   --max-iterations N  Maximum number of swap attempts (default 5000)
   --convergence N     Stop after N consecutive non-improving swaps (default 500)
   --seed N            Random seed for reproducibility
   -h, --help          Show this help message

=head1 DESCRIPTION

C<plan_stillage.pl> uses L<BeerFestDB::StillagePlanner> to assign all
unplaced casks for a festival (C<cask_management> rows whose
C<stillage_location_id> is NULL and C<cask_graveyard> is NULL) to the
bay positions defined in the YAML config file.

If the config contains a C<product_categories> list, only casks whose
product belongs to one of the named categories are considered.  If it
contains a C<dispense_methods> list, only casks whose container size
has a matching dispense method are considered.  These filters may be
combined and allow separate planning runs for e.g. cask beer vs.
bottle and keyleg products.

The script prints a human-readable plan to standard output.  Pass
C<--apply> to write C<stillage_location_id>, C<stillage_bay>, and
C<bay_position_id> back to the C<cask_management> table.  Casks that
cannot fit in any available bay position have their C<cask_graveyard>
set to C<"deck">.

The script will prompt interactively for the festival unless
C<current_festival> is set in the BeerFestDB configuration.  All
physical constraints (stillage descriptions, bay widths, container
widths, and scoring weights) are read from the C<--config> YAML file.
See C<example_data/stillage_plan.yml> for an annotated example.

=head2 Reproducibility

Because the hill-climber uses random pair selection, different runs
may produce slightly different layouts.  Use C<--seed N> to fix the
random seed and obtain repeatable results.

=head1 SEE ALSO

L<BeerFestDB::StillagePlanner>, L<BeerFestDB::StillagePlanner::Config>,
L<BeerFestDB::StillagePlanner::SlotGroup>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut
