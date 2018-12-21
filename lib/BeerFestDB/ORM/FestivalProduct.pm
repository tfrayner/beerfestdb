use utf8;
package BeerFestDB::ORM::FestivalProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::FestivalProduct

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<festival_product>

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

=head2 sale_currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sale_price

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "festival_product_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sale_volume_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sale_currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sale_price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</festival_product_id>

=back

=cut

__PACKAGE__->set_primary_key("festival_product_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<festival_id>

=over 4

=item * L</festival_id>

=item * L</product_id>

=back

=cut

__PACKAGE__->add_unique_constraint("festival_id", ["festival_id", "product_id"]);

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

=head2 gyles

Type: has_many

Related object: L<BeerFestDB::ORM::Gyle>

=cut

__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.festival_product_id" => "self.festival_product_id" },
  undef,
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

=head2 sale_currency_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "sale_currency_id",
  "BeerFestDB::ORM::Currency",
  { currency_id => "sale_currency_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OkLkHK35yC/sMfZ1FgM8zQ


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->product_id->repr();
}

1;
