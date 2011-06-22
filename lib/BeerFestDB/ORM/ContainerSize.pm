package BeerFestDB::ORM::ContainerSize;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ContainerSize

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

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "container_size_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "container_volume",
  { data_type => "decimal", is_nullable => 0, size => [4, 2] },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("container_size_id");
__PACKAGE__->add_unique_constraint("container_volume", ["container_volume"]);
__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.container_size_id" => "self.container_size_id" },
  {},
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

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.container_size_id" => "self.container_size_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-04 14:38:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gSdImzk8EPAUPKBDu+BY5w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
