use utf8;
package BeerFestDB::ORM::ContainerSize;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ContainerSize

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<container_size>

=cut

__PACKAGE__->table("container_size");

=head1 ACCESSORS

=head2 container_size_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 container_volume

  data_type: 'decimal'
  is_nullable: 0
  size: [4,2]

=head2 container_measure_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dispense_method_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "container_size_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "container_volume",
  { data_type => "decimal", is_nullable => 0, size => [4, 2] },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dispense_method_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</container_size_id>

=back

=cut

__PACKAGE__->set_primary_key("container_size_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<container_volume>

=over 4

=item * L</container_volume>

=item * L</container_measure_id>

=item * L</dispense_method_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "container_volume",
  [
    "container_volume",
    "container_measure_id",
    "dispense_method_id",
  ],
);

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 cask_managements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskManagement>

=cut

__PACKAGE__->has_many(
  "cask_managements",
  "BeerFestDB::ORM::CaskManagement",
  { "foreign.container_size_id" => "self.container_size_id" },
  undef,
);

=head2 container_measure_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerMeasure>

=cut

__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);

=head2 dispense_method_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::DispenseMethod>

=cut

__PACKAGE__->belongs_to(
  "dispense_method_id",
  "BeerFestDB::ORM::DispenseMethod",
  { dispense_method_id => "dispense_method_id" },
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.container_size_id" => "self.container_size_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-07 20:32:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ntyHyIIqJvMaBoDbvf+M/A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
