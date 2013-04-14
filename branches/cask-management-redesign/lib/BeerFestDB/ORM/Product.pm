use utf8;
package BeerFestDB::ORM::Product;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Product

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product>

=cut

__PACKAGE__->table("product");

=head1 ACCESSORS

=head2 product_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 product_category_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_style_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 nominal_abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 long_description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "product_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "product_category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_style_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "nominal_abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "description",
  { data_type => "text", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "long_description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</product_id>

=back

=cut

__PACKAGE__->set_primary_key("product_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<company_id>

=over 4

=item * L</company_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("company_id", ["company_id", "name"]);

=head1 RELATIONS

=head2 company_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);

=head2 festival_products

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.product_id" => "self.product_id" },
  {},
);

=head2 product_category_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductCategory>

=cut

__PACKAGE__->belongs_to(
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);

=head2 product_characteristics

Type: has_many

Related object: L<BeerFestDB::ORM::ProductCharacteristic>

=cut

__PACKAGE__->has_many(
  "product_characteristics",
  "BeerFestDB::ORM::ProductCharacteristic",
  { "foreign.product_id" => "self.product_id" },
  {},
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.product_id" => "self.product_id" },
  {},
);

=head2 product_style_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductStyle>

=cut

__PACKAGE__->belongs_to(
  "product_style_id",
  "BeerFestDB::ORM::ProductStyle",
  { product_style_id => "product_style_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-04-14 21:48:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g7ABjKztoevcCHbtRSLULA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->many_to_many(
    "festivals" => "festival_products", "festival_id"
);

1;
