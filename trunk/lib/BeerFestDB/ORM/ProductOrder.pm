package BeerFestDB::ORM::ProductOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ProductOrder

=cut

__PACKAGE__->table("product_order");

=head1 ACCESSORS

=head2 product_order_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 distributor_company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 container_size_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 cask_count

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 currency_code

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 advertised_price

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 is_final

  data_type: 'tinyint'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "product_order_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "distributor_company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "container_size_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cask_count",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "currency_code",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 3 },
  "advertised_price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "is_final",
  { data_type => "tinyint", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("product_order_id");
__PACKAGE__->add_unique_constraint(
  "festival_product_order",
  [
    "festival_id",
    "product_id",
    "distributor_company_id",
    "container_size_id",
    "cask_count",
  ],
);

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

=head2 distributor_company_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->belongs_to(
  "distributor_company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "distributor_company_id" },
);

=head2 currency_code

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "currency_code" },
);

=head2 container_size_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContainerSize>

=cut

__PACKAGE__->belongs_to(
  "container_size_id",
  "BeerFestDB::ORM::ContainerSize",
  { container_size_id => "container_size_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-09-18 15:42:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lsf0M5BHBBGZmQw1AYDt/Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
