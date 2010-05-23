package BeerFestDB::ORM::ProductCharacteristic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ProductCharacteristic

=cut

__PACKAGE__->table("product_characteristic");

=head1 ACCESSORS

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_characteristic_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_characteristic_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "value",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("product_id");

=head1 RELATIONS

=head2 product_characteristic_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductCharacteristicType>

=cut

__PACKAGE__->belongs_to(
  "product_characteristic_type_id",
  "BeerFestDB::ORM::ProductCharacteristicType",
  {
    "product_characteristic_type_id" => "product_characteristic_type_id",
  },
);

=head2 product_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->belongs_to(
  "product_id",
  "BeerFestDB::ORM::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MW8nJuJzoyEE5Mz3JEteSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
