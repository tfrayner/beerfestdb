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

package BeerFestDB::StillagePlanner::CaskEntry;

use 5.008;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

=head1 NAME

BeerFestDB::StillagePlanner::CaskEntry - Cask descriptor for stillage planning

=head1 SYNOPSIS

  use BeerFestDB::StillagePlanner::CaskEntry;

  my $entry = BeerFestDB::StillagePlanner::CaskEntry->new(
      cask_management     => $cm_row,
      beer_name           => 'Old Peculier',
      brewery_name        => 'Theakstons',
      sort_key            => 'theakstons old peculier',
      cask_number         => 1,
      cask_count          => 3,
      is_sale_or_return   => 0,
      container_type      => 'firkin',
      festival_product_id => 42,
  );

=head1 DESCRIPTION

A value object representing a single C<cask_management> row for the
purposes of stillage planning.  Pre-computed metadata (brewery name,
beer name, sort key, etc.) avoids repeated ORM traversals during the
optimisation inner loop.

=head1 ATTRIBUTES

=head2 cask_management

The underlying L<BeerFestDB::ORM::CaskManagement> row.

=cut

has 'cask_management' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 beer_name

Product name of the beer (from the C<product> table).

=cut

has 'beer_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 brewery_name

Name of the producing company (from the C<company> table).

=cut

has 'brewery_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 sort_key

Lower-cased C<"$brewery_name $beer_name"> string used for alphabetical
ordering comparisons.

=cut

has 'sort_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 cask_number

Ordinal position of this cask within its beer (1 = first by
C<cellar_reference>, 2 = second, etc.).  Mutably set by
L<BeerFestDB::StillagePlanner/load_casks> once all casks for a beer
are known.

=cut

has 'cask_number' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

=head2 cask_count

Total number of active casks for this beer on the stillage.  Set at
the same time as L</cask_number>.

=cut

has 'cask_count' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

=head2 is_sale_or_return

Boolean; true when this cask is sale-or-return.  SOR casks receive a
lower deck-placement penalty because they can be returned unsold
without financial loss.

=cut

has 'is_sale_or_return' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 container_type

Human-readable container size description (e.g. C<"firkin"> or
C<"kilderkin">) taken from the C<container_size> table.

=cut

has 'container_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 festival_product_id

Integer primary key of the C<festival_product> row.  Used to group
casks that belong to the same beer during scoring.

=cut

has 'festival_product_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=head2 cask_width

Physical width of this cask in metres, looked up from the planner
config via the container size description.  Used by
L<BeerFestDB::StillagePlanner::SlotGroup/can_fit> to enforce bay
position capacity.

=cut

has 'cask_width' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

=head1 METHODS

=head2 label

Returns a compact human-readable label suitable for rendering the
stillage layout, e.g. C<"Old Peculier (firkin) 1/3">.

=cut

sub label {
    my ($self) = @_;
    return sprintf( '%s / %s (%s) %d/%d',
        $self->brewery_name,
        $self->beer_name,
        $self->container_type,
        $self->cask_number,
        $self->cask_count,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut
