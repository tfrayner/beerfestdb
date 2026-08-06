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

package BeerFestDB::StillagePlanner::Config;

use 5.008;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Carp;
use YAML::Tiny;

use BeerFestDB::StillagePlanner::SlotGroup;

our $VERSION = '0.01';

=head1 NAME

BeerFestDB::StillagePlanner::Config - YAML configuration for StillagePlanner

=head1 SYNOPSIS

  use BeerFestDB::StillagePlanner::Config;

  my $config = BeerFestDB::StillagePlanner::Config->new(
      config_file => 'stillage_plan.yml',
  );

  my $margin = $config->margin;
  my $w      = $config->container_width_for('firkin');
  my @groups = @{ $config->build_slot_groups($schema) };

=head1 DESCRIPTION

Parses a YAML planning configuration file and exposes its settings to
L<BeerFestDB::StillagePlanner>.  The config file specifies:

=over 4

=item * A margin fraction (default 0.10) added to each cask width to
avoid casks touching.

=item * A mapping of C<container_size> descriptions to physical widths in
metres.

=item * The set of stillages to plan, with their bays and bay positions,
each bay position having a physical width in metres.

=item * Optional scoring weights (with the same defaults as
L<BeerFestDB::StillagePlanner>).

=back

=head2 Example YAML

  ---
  margin: 0.10

  container_widths:
    firkin:     0.45
    kilderkin:  0.58
    22 gallon:  0.65
    barrel:     0.72

  stillages:
    - description: South Bar
      bays:
        - number: 1
          positions:
            - bay_position: Bottom Front
              width: 4.0
            - bay_position: Top Front
              width: 4.0
        - number: 2
          positions:
            - bay_position: Bottom Front
              width: 3.6

  weights:
    alphabetical:        10
    proximity:            5
    deck:                20
    pull_through:        15
    sor_deck_multiplier: 0.1
    stillage:           1000

=head1 ATTRIBUTES

=head2 config_file

Path to the YAML configuration file.  Required.

=cut

has 'config_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_data' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_load',
);

# ── Private ───────────────────────────────────────────────────────────────────

sub _load {
    my ($self) = @_;
    my $file = $self->config_file;
    croak "Config file not found: $file" unless -f $file;
    my $yaml = YAML::Tiny->read($file)
        or croak "Failed to parse YAML config '$file': " . YAML::Tiny->errstr;
    croak "Config file '$file' is empty" unless defined $yaml->[0];
    return $yaml->[0];
}

# ── Public accessors ──────────────────────────────────────────────────────────

=head1 METHODS

=head2 margin

Returns the margin fraction (default 0.10).  This is multiplied by the
cask width to compute the spacing gap around each cask, so the
effective cask pitch is C<cask_width * (1 + margin)>.

=cut

sub margin {
    my ($self) = @_;
    return $self->_data->{margin} // 0.10;
}

=head2 container_width_for($description)

Returns the configured physical width (in metres) for the named
container size.  Dies with a clear message if the description is not
present in the C<container_widths> section of the config.

=cut

sub container_width_for {
    my ( $self, $description ) = @_;
    my $widths = $self->_data->{container_widths} // {};
    croak "No width configured for container size '$description' "
        . "(check the container_widths section of your config file)"
        unless exists $widths->{$description};
    return $widths->{$description};
}

=head2 container_widths

Returns the full C<container_widths> hash ref (description → metres).

=cut

sub container_widths {
    my ($self) = @_;
    return $self->_data->{container_widths} // {};
}

=head2 weight($name, $default)

Returns the named scoring weight from the C<weights> section of the
config, falling back to C<$default> if it is not specified.

=cut

sub weight {
    my ( $self, $name, $default ) = @_;
    return ( $self->_data->{weights} // {} )->{$name} // $default;
}

=head2 product_categories

Returns an array-ref of C<product_category> description strings that
should be included in the plan (e.g. C<["beer", "foreign beer"]>),
or C<undef> if no C<product_categories> key is present in the config
(meaning B<all> product categories are included).

Example YAML:

  product_categories:
    - beer
    - foreign beer

=cut

sub product_categories {
    my ($self) = @_;
    my $cats = $self->_data->{product_categories};
    return undef unless defined $cats;
    return ref($cats) eq 'ARRAY' ? $cats : [$cats];
}

=head2 dispense_methods

Returns an array-ref of C<dispense_method> description strings that
should be included in the plan (e.g. C<["cask"]>),
or C<undef> if no C<dispense_methods> key is present in the config
(meaning B<all> dispense methods are included).

The dispense method is taken from the C<container_size> linked to each
C<cask_management> row.

Example YAML:

  dispense_methods:
    - cask

=cut

sub dispense_methods {
    my ($self) = @_;
    my $dms = $self->_data->{dispense_methods};
    return undef unless defined $dms;
    return ref($dms) eq 'ARRAY' ? $dms : [$dms];
}

=head2 build_slot_groups($schema, $festival)

Constructs and returns an array-ref of
L<BeerFestDB::StillagePlanner::SlotGroup> objects by resolving the
C<stillages> section of the config against the database.

Dies if a named C<StillageLocation> or C<BayPosition> cannot be found.

=cut

sub build_slot_groups {
    my ( $self, $schema, $festival ) = @_;

    my @groups;
    my $margin = $self->margin;

    for my $sl_cfg ( @{ $self->_data->{stillages} // [] } ) {

        my $desc = $sl_cfg->{description}
            or croak "Stillage config entry missing 'description'";

        my $sl = $schema->resultset('StillageLocation')
            ->search( {
                description => $desc,
                festival_id => $festival->get_column('festival_id')
            } )->first
                or croak "StillageLocation '$desc' not found for festival";

        for my $bay_cfg ( @{ $sl_cfg->{bays} // [] } ) {

            my $bay_num = $bay_cfg->{number}
                or croak "Bay config entry missing 'number' "
                    . "in stillage '$desc'";

            for my $pos_cfg ( @{ $bay_cfg->{positions} // [] } ) {

                my $pos_desc = $pos_cfg->{bay_position}
                    or croak "Position config entry missing 'bay_position' "
                        . "in stillage '$desc', bay $bay_num";

                my $bp = $schema->resultset('BayPosition')
                    ->find( { description => $pos_desc } )
                    or croak "BayPosition '$pos_desc' not found in the database";

                my $width = $pos_cfg->{width}
                    or croak "Position config entry missing 'width' "
                        . "for '$pos_desc' in stillage '$desc', bay $bay_num";

                push @groups, BeerFestDB::StillagePlanner::SlotGroup->new(
                    stillage_location => $sl,
                    bay_number        => $bay_num,
                    bay_position      => $bp,
                    width             => $width,
                    margin            => $margin,
                );
            }
        }
    }

    croak "No slot groups defined in config; "
        . "check the 'stillages' section of your config file"
        unless @groups;

    return \@groups;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut
