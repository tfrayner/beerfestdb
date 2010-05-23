package BeerFestDB::ORM::FestivalProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::FestivalProduct

=cut

__PACKAGE__->table("festival_product");

=head1 ACCESSORS

=head2 festival_product_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sale_volume_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sale_currency_code

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 sale_price

  data_type: 'integer'
  is_nullable: 1

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "festival_product_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sale_volume_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sale_currency_code",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 3 },
  "sale_price",
  { data_type => "integer", is_nullable => 1 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("festival_product_id", "product_id", "festival_id");
__PACKAGE__->add_unique_constraint("festival_product_id", ["festival_product_id"]);

=head1 RELATIONS

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
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

=head2 sale_volume_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::SaleVolume>

=cut

__PACKAGE__->belongs_to(
  "sale_volume_id",
  "BeerFestDB::ORM::SaleVolume",
  { sale_volume_id => "sale_volume_id" },
);

=head2 sale_currency_code

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "sale_currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "sale_currency_code" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8IN0Drt4OV9y9a9JVXyVZg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
