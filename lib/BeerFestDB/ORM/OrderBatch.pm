package BeerFestDB::ORM::OrderBatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::OrderBatch

=cut

__PACKAGE__->table("order_batch");

=head1 ACCESSORS

=head2 order_batch_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 order_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "order_batch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "order_date",
  { data_type => "date", "datetime_undef_if_invalid" => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("order_batch_id");
__PACKAGE__->add_unique_constraint("festival_order_batch", ["festival_id", "description"]);

=head1 RELATIONS

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.order_batch_id" => "self.order_batch_id" },
  {},
);

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.order_batch_id" => "self.order_batch_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-19 11:31:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KJK2dr+la/j8CpJQYTfFoQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
