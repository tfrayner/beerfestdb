package BeerFestDB::ORM::ProductCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ProductCategory

=cut

__PACKAGE__->table("product_category");

=head1 ACCESSORS

=head2 product_category_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "product_category_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("product_category_id");
__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 products

Type: has_many

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.product_category_id" => "self.product_category_id" },
  {},
);

=head2 product_characteristic_types

Type: has_many

Related object: L<BeerFestDB::ORM::ProductCharacteristicType>

=cut

__PACKAGE__->has_many(
  "product_characteristic_types",
  "BeerFestDB::ORM::ProductCharacteristicType",
  { "foreign.product_category_id" => "self.product_category_id" },
  {},
);

=head2 product_styles

Type: has_many

Related object: L<BeerFestDB::ORM::ProductStyle>

=cut

__PACKAGE__->has_many(
  "product_styles",
  "BeerFestDB::ORM::ProductStyle",
  { "foreign.product_category_id" => "self.product_category_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/i5oSHLq8WTk7j0jbQde+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
