package BeerFestDB::ORM::Currency;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Currency

=cut

__PACKAGE__->table("currency");

=head1 ACCESSORS

=head2 currency_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 currency_code

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 currency_number

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 currency_format

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 exponent

  data_type: 'tinyint'
  is_nullable: 0

=head2 currency_symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "currency_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "currency_code",
  { data_type => "char", is_nullable => 0, size => 3 },
  "currency_number",
  { data_type => "char", is_nullable => 0, size => 3 },
  "currency_format",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "exponent",
  { data_type => "tinyint", is_nullable => 0 },
  "currency_symbol",
  { data_type => "varchar", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("currency_id");

=head1 RELATIONS

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.currency_id" => "self.currency_id" },
  {},
);

=head2 festival_entries

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalEntry>

=cut

__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  { "foreign.currency_id" => "self.currency_id" },
  {},
);

=head2 festival_products

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.sale_currency_id" => "self.currency_id" },
  {},
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.currency_id" => "self.currency_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-09-19 14:43:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vsZSP8MdECITT9k5+fRd8Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
