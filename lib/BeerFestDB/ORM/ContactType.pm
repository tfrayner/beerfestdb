use utf8;
package BeerFestDB::ORM::ContactType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::ContactType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<contact_type>

=cut

__PACKAGE__->table("contact_type");

=head1 ACCESSORS

=head2 contact_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "contact_type_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contact_type_id>

=back

=cut

__PACKAGE__->set_primary_key("contact_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 contacts

Type: has_many

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.contact_type_id" => "self.contact_type_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fUE2fdy+EyNU3F0StM/TcA


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return $self->description;
}

1;
