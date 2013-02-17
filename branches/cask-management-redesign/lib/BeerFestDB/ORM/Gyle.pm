use utf8;
package BeerFestDB::ORM::Gyle;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Gyle

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gyle>

=cut

__PACKAGE__->table("gyle");

=head1 ACCESSORS

=head2 gyle_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 festival_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 external_reference

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 internal_reference

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "gyle_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "festival_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "external_reference",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "internal_reference",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gyle_id>

=back

=cut

__PACKAGE__->set_primary_key("gyle_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<festival_product_id>

=over 4

=item * L</festival_product_id>

=item * L</internal_reference>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "festival_product_id",
  ["festival_product_id", "internal_reference"],
);

=head1 RELATIONS

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.gyle_id" => "self.gyle_id" },
  {},
);

=head2 company_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);

=head2 festival_product_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::FestivalProduct>

=cut

__PACKAGE__->belongs_to(
  "festival_product_id",
  "BeerFestDB::ORM::FestivalProduct",
  { festival_product_id => "festival_product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3CnzYMFku3CBSg5tZ7ZQQg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
