use utf8;
package BeerFestDB::ORM::ProductAllergen;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProductAllergen

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_allergen>

=cut

__PACKAGE__->table("product_allergen");

=head1 ACCESSORS

=head2 product_allergen_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_allergen_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 present

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "product_allergen_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "product_allergen_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "present",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</product_allergen_id>

=back

=cut

__PACKAGE__->set_primary_key("product_allergen_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<product_allergen_mapping>

=over 4

=item * L</product_id>

=item * L</product_allergen_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "product_allergen_mapping",
  ["product_id", "product_allergen_type_id"],
);

=head1 RELATIONS

=head2 product_allergen_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductAllergenType>

=cut

__PACKAGE__->belongs_to(
  "product_allergen_type_id",
  "BeerFestDB::ORM::ProductAllergenType",
  { product_allergen_type_id => "product_allergen_type_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-04 16:26:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V0vAeCRsaY8lNak6CtorJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return sprintf("%s: %s",
				      $self->product_id->repr(),
				      $self->product_allergen_type_id->repr());
}

1;
