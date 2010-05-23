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
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 container_description

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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "container_description",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("container_size_id");
__PACKAGE__->add_unique_constraint("container_description", ["container_description"]);

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


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z6wW/6/Xvhk0/w98Rp9xqQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
