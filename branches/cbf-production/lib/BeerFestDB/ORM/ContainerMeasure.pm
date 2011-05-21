package BeerFestDB::ORM::ContainerMeasure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ContainerMeasure

=cut

__PACKAGE__->table("container_measure");

=head1 ACCESSORS

=head2 container_measure_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 litre_multiplier

  data_type: 'float'
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "container_measure_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "litre_multiplier",
  { data_type => "float", is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);
__PACKAGE__->set_primary_key("container_measure_id");
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
  {},
);

=head2 container_sizes

Type: has_many

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->has_many(
  "container_sizes",
  "BeerFestDB::ORM::ContainerSize",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  {},
);

=head2 sale_volumes

Type: has_many

Related object: L<BeerFestDB::ORM::SaleVolume>

=cut

__PACKAGE__->has_many(
  "sale_volumes",
  "BeerFestDB::ORM::SaleVolume",
  { "foreign.container_measure_id" => "self.container_measure_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-09-18 15:42:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HqqdtCiaW0IEbXUI3ttGLQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;