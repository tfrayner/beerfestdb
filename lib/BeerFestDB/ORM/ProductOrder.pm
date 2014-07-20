use utf8;
package BeerFestDB::ORM::ProductOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProductOrder

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_order>

=cut

__PACKAGE__->table("product_order");

=head1 ACCESSORS

=head2 product_order_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 order_batch_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 distributor_company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 container_size_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cask_count

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 advertised_price

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 is_final

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_received

  data_type: 'tinyint'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 is_sale_or_return

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "product_order_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "order_batch_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "distributor_company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "container_size_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cask_count",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "advertised_price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "is_final",
  { data_type => "tinyint", is_nullable => 1 },
  "is_received",
  { data_type => "tinyint", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "is_sale_or_return",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</product_order_id>

=back

=cut

__PACKAGE__->set_primary_key("product_order_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<product_order_batch>

=over 4

=item * L</order_batch_id>

=item * L</product_id>

=item * L</distributor_company_id>

=item * L</container_size_id>

=item * L</cask_count>

=item * L</is_sale_or_return>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "product_order_batch",
  [
    "order_batch_id",
    "product_id",
    "distributor_company_id",
    "container_size_id",
    "cask_count",
    "is_sale_or_return",
  ],
);

=head1 RELATIONS

=head2 cask_managements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskManagement>

=cut

__PACKAGE__->has_many(
  "cask_managements",
  "BeerFestDB::ORM::CaskManagement",
  { "foreign.product_order_id" => "self.product_order_id" },
  undef,
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

=head2 currency_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_id",
  "BeerFestDB::ORM::Currency",
  { currency_id => "currency_id" },
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

=head2 order_batch_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::OrderBatch>

=cut

__PACKAGE__->belongs_to(
  "order_batch_id",
  "BeerFestDB::ORM::OrderBatch",
  { order_batch_id => "order_batch_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hJpCZZ5VsITocCrUvJY0vQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
