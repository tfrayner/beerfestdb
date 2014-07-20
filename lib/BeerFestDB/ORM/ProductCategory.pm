use utf8;
package BeerFestDB::ORM::ProductCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProductCategory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_category>

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

=head1 PRIMARY KEY

=over 4

=item * L</product_category_id>

=back

=cut

__PACKAGE__->set_primary_key("product_category_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 category_auths

Type: has_many

Related object: L<BeerFestDB::ORM::CategoryAuth>

=cut

__PACKAGE__->has_many(
  "category_auths",
  "BeerFestDB::ORM::CategoryAuth",
  { "foreign.product_category_id" => "self.product_category_id" },
  undef,
);

=head2 product_characteristic_types

Type: has_many

Related object: L<BeerFestDB::ORM::ProductCharacteristicType>

=cut

__PACKAGE__->has_many(
  "product_characteristic_types",
  "BeerFestDB::ORM::ProductCharacteristicType",
  { "foreign.product_category_id" => "self.product_category_id" },
  undef,
);

=head2 product_styles

Type: has_many

Related object: L<BeerFestDB::ORM::ProductStyle>

=cut

__PACKAGE__->has_many(
  "product_styles",
  "BeerFestDB::ORM::ProductStyle",
  { "foreign.product_category_id" => "self.product_category_id" },
  undef,
);

=head2 products

Type: has_many

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.product_category_id" => "self.product_category_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Efrh7iWm+Q98Wmt1vDET4g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
