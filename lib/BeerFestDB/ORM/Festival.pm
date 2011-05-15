package BeerFestDB::ORM::Festival;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Festival

=cut

__PACKAGE__->table("festival");

=head1 ACCESSORS

=head2 festival_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 year

  data_type: 'year'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 fst_start_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 fst_end_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "festival_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "year",
  { data_type => "year", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "fst_start_date",
  { data_type => "date", "datetime_undef_if_invalid" => 1, is_nullable => 1 },
  "fst_end_date",
  { data_type => "date", "datetime_undef_if_invalid" => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("festival_id");

=head1 RELATIONS

=head2 bars

Type: has_many

Related object: L<BeerFestDB::ORM::Bar>

=cut

__PACKAGE__->has_many(
  "bars",
  "BeerFestDB::ORM::Bar",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 festival_openings

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalOpening>

=cut

__PACKAGE__->has_many(
  "festival_openings",
  "BeerFestDB::ORM::FestivalOpening",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 festival_products

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 measurement_batches

Type: has_many

Related object: L<BeerFestDB::ORM::MeasurementBatch>

=cut

__PACKAGE__->has_many(
  "measurement_batches",
  "BeerFestDB::ORM::MeasurementBatch",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 order_batches

Type: has_many

Related object: L<BeerFestDB::ORM::OrderBatch>

=cut

__PACKAGE__->has_many(
  "order_batches",
  "BeerFestDB::ORM::OrderBatch",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);

=head2 stillage_locations

Type: has_many

Related object: L<BeerFestDB::ORM::StillageLocation>

=cut

__PACKAGE__->has_many(
  "stillage_locations",
  "BeerFestDB::ORM::StillageLocation",
  { "foreign.festival_id" => "self.festival_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-04-29 20:57:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yxo/O/l9lDBiy/m+cQ+t8w


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->many_to_many(
    "products" => "festival_products", "product_id"
);

1;
