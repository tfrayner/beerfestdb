use utf8;
package BeerFestDB::ORM::ContainerMeasure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ContainerMeasure

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<container_measure>

=cut

__PACKAGE__->table("container_measure");

=head1 ACCESSORS

=head2 container_measure_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 litre_multiplier

  data_type: 'decimal'
  is_nullable: 0
  size: [15,12]

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "container_measure_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "litre_multiplier",
  { data_type => "decimal", is_nullable => 0, size => [15, 12] },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</container_measure_id>

=back

=cut

__PACKAGE__->set_primary_key("container_measure_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 cask_measurements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskMeasurement>

=cut

__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  undef,
);

=head2 container_sizes

Type: has_many

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->has_many(
  "container_sizes",
  "BeerFestDB::ORM::ContainerSize",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  undef,
);

=head2 sale_volumes

Type: has_many

Related object: L<BeerFestDB::ORM::SaleVolume>

=cut

__PACKAGE__->has_many(
  "sale_volumes",
  "BeerFestDB::ORM::SaleVolume",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-13 17:36:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AT/iwiaxovO9CXcLGDTP+g


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->description;
}

1;
