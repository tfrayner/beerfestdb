package BeerFestDB::ORM::CaskMeasurement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::CaskMeasurement

=cut

__PACKAGE__->table("cask_measurement");

=head1 ACCESSORS

=head2 cask_measurement_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cask_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 start_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 end_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 volume

  data_type: 'decimal'
  is_nullable: 0
  size: [5,2]

=head2 container_measure_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cask_measurement_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cask_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "start_date",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "end_date",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "volume",
  { data_type => "decimal", is_nullable => 0, size => [5, 2] },
  "container_measure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cask_measurement_id");

=head1 RELATIONS

=head2 cask_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->belongs_to("cask_id", "BeerFestDB::ORM::Cask", { cask_id => "cask_id" });

=head2 container_measure_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerMeasure>

=cut

__PACKAGE__->belongs_to(
  "container_measure_id",
  "BeerFestDB::ORM::ContainerMeasure",
  { container_measure_id => "container_measure_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-26 18:58:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ongqDa7H6OHKzwMfomrFYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
