use utf8;
package BeerFestDB::ORM::ProductAllergenType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ProductAllergenType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_allergen_type>

=cut

__PACKAGE__->table("product_allergen_type");

=head1 ACCESSORS

=head2 product_allergen_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "product_allergen_type_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</product_allergen_type_id>

=back

=cut

__PACKAGE__->set_primary_key("product_allergen_type_id");

=head1 RELATIONS

=head2 product_allergens

Type: has_many

Related object: L<BeerFestDB::ORM::ProductAllergen>

=cut

__PACKAGE__->has_many(
  "product_allergens",
  "BeerFestDB::ORM::ProductAllergen",
  {
    "foreign.product_allergen_type_id" => "self.product_allergen_type_id",
  },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-01 13:24:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kge4N9QlnsXXVH+EfV/RsA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->description;
}

1;
