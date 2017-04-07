use utf8;
package BeerFestDB::ORM::CategoryAuth;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::CategoryAuth

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<category_auth>

=cut

__PACKAGE__->table("category_auth");

=head1 ACCESSORS

=head2 category_auth_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 product_category_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "category_auth_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "product_category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</category_auth_id>

=back

=cut

__PACKAGE__->set_primary_key("category_auth_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<category_role_id>

=over 4

=item * L</product_category_id>

=item * L</role_id>

=back

=cut

__PACKAGE__->add_unique_constraint("category_role_id", ["product_category_id", "role_id"]);

=head1 RELATIONS

=head2 product_category_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ProductCategory>

=cut

__PACKAGE__->belongs_to(
  "product_category_id",
  "BeerFestDB::ORM::ProductCategory",
  { product_category_id => "product_category_id" },
);

=head2 role_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Role>

=cut

__PACKAGE__->belongs_to("role_id", "BeerFestDB::ORM::Role", { role_id => "role_id" });


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-04-25 23:31:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ppahj/WUhNMgJJ/YlwftKA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return sprintf("%s: %s",
				      $self->product_category_id->repr(),
				      $self->role_id->repr());
}

1;
