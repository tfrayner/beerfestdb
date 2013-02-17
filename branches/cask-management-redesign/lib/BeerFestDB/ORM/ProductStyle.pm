use utf8;
package BeerFestDB::ORM::ProductStyle;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProductStyle

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_style>

=cut

__PACKAGE__->table("product_style");

=head1 ACCESSORS

=head2 product_style_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 product_category_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "product_style_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "product_category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</product_style_id>

=back

=cut

__PACKAGE__->set_primary_key("product_style_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<product_category_id>

=over 4

=item * L</product_category_id>

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("product_category_id", ["product_category_id", "description"]);

=head1 RELATIONS

=head2 product_category_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductCategory>

=cut

__PACKAGE__->belongs_to(
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);

=head2 products

Type: has_many

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.product_style_id" => "self.product_style_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XsTUG/XyGuWODmGn4spWiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
