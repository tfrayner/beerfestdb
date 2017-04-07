use utf8;
package BeerFestDB::ORM::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::UserRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_role>

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 user_role_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_role_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_role_id>

=back

=cut

__PACKAGE__->set_primary_key("user_role_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_id>

=over 4

=item * L</user_id>

=item * L</role_id>

=back

=cut

__PACKAGE__->add_unique_constraint("user_id", ["user_id", "role_id"]);

=head1 RELATIONS

=head2 role_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Role>

=cut

__PACKAGE__->belongs_to("role_id", "BeerFestDB::ORM::Role", { role_id => "role_id" });

=head2 user_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::User>

=cut

__PACKAGE__->belongs_to("user_id", "BeerFestDB::ORM::User", { user_id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-02-03 20:20:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1+rS8R2rcPXGNUMjUrsTsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return sprintf("%s: %s",
				      $self->user_id->repr(),
				      $self->role_id->repr());
}

1;
