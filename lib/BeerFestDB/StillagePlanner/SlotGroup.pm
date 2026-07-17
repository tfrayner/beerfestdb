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

package BeerFestDB::StillagePlanner::SlotGroup;

use 5.008;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use POSIX qw(floor);

our $VERSION = '0.01';

=head1 NAME

BeerFestDB::StillagePlanner::SlotGroup - A physical bay position slot for planning

=head1 SYNOPSIS

  use BeerFestDB::StillagePlanner::SlotGroup;

  my $group = BeerFestDB::StillagePlanner::SlotGroup->new(
      stillage_location => $sl_row,
      bay_number        => 1,
      bay_position      => $bp_row,
      width             => 4.0,    # metres
      margin            => 0.10,
  );

  my $cap = $group->capacity_for(0.45);  # how many firkins fit?
  print $group->label;

=head1 DESCRIPTION

Represents one C<(stillage_location, bay_number, bay_position)>
combination with a physical width and the configured margin fraction.
Multiple casks can be assigned to the same slot group, constrained by
their combined effective width (raw width × (1 + margin)).

=head1 ATTRIBUTES

=head2 stillage_location

The L<BeerFestDB::ORM::StillageLocation> row.

=cut

has 'stillage_location' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 bay_number

Integer bay number within the stillage.

=cut

has 'bay_number' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=head2 bay_position

The L<BeerFestDB::ORM::BayPosition> row.

=cut

has 'bay_position' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 width

Physical width of this bay position in metres.

=cut

has 'width' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

=head2 margin

Fractional margin added to each cask width (default 0.10).  The
effective pitch of one cask is C<cask_width * (1 + margin)>.

=cut

has 'margin' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.10,
);

=head1 METHODS

=head2 capacity_for($cask_width)

Returns the maximum number of casks of the given raw width (in metres)
that can fit in this slot group, applying the configured margin.

  capacity = floor( width / (cask_width * (1 + margin)) )

=cut

sub capacity_for {
    my ( $self, $cask_width ) = @_;
    return floor( $self->width / ( $cask_width * ( 1 + $self->margin ) ) );
}

=head2 can_fit($used_width, $cask_width)

Returns true if one more cask of C<$cask_width> can be added to this
slot group given that C<$used_width> metres of effective width are
already occupied.

=cut

sub can_fit {
    my ( $self, $used_width, $cask_width ) = @_;
    return ( $used_width + $cask_width * ( 1 + $self->margin ) )
        <= ( $self->width + 1e-9 );
}

=head2 id

Returns a compact string uniquely identifying this slot group within a
planning run: C<"$stillage_location_id:$bay_number:$bay_position_id">.

=cut

sub id {
    my ($self) = @_;
    return sprintf( '%d:%d:%d',
        $self->stillage_location->get_column('stillage_location_id'),
        $self->bay_number,
        $self->bay_position->get_column('bay_position_id'),
    );
}

=head2 bay_id

Returns a string identifying just the stillage + bay, used for
proximity and pull-through scoring: C<"$stillage_location_id:$bay_number">.

=cut

sub bay_id {
    my ($self) = @_;
    return sprintf( '%d:%d',
        $self->stillage_location->get_column('stillage_location_id'),
        $self->bay_number,
    );
}

=head2 label

Returns a human-readable label, e.g.
C<"South Bar / Bay 1 / Bottom Front (4.00m)">.

=cut

sub label {
    my ($self) = @_;
    return sprintf( '%s / Bay %d / %s (%.2fm)',
        $self->stillage_location->description,
        $self->bay_number,
        $self->bay_position->description,
        $self->width,
    );
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
