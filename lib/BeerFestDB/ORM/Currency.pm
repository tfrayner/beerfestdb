use utf8;
package BeerFestDB::ORM::Currency;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Currency

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<currency>

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

=head1 PRIMARY KEY

=over 4

=item * L</currency_id>

=back

=cut

__PACKAGE__->set_primary_key("currency_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<currency_code>

=over 4

=item * L</currency_code>

=back

=cut

__PACKAGE__->add_unique_constraint("currency_code", ["currency_code"]);

=head1 RELATIONS

=head2 cask_managements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskManagement>

=cut

__PACKAGE__->has_many(
  "cask_managements",
  "BeerFestDB::ORM::CaskManagement",
  { "foreign.currency_id" => "self.currency_id" },
  undef,
);

=head2 festival_entries

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalEntry>

=cut

__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  { "foreign.currency_id" => "self.currency_id" },
  undef,
);

=head2 festival_products

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->has_many(
  "festival_products",
  "BeerFestDB::ORM::FestivalProduct",
  { "foreign.sale_currency_id" => "self.currency_id" },
  undef,
);

=head2 product_orders

Type: has_many

Related object: L<BeerFestDB::ORM::ProductOrder>

=cut

__PACKAGE__->has_many(
  "product_orders",
  "BeerFestDB::ORM::ProductOrder",
  { "foreign.currency_id" => "self.currency_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YH8SpPH/vAd43vQ8UxMIlw


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->currency_code;
}

1;
