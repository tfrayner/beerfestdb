use utf8;
package BeerFestDB::ORM::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Contact

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<contact>

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contact_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 first_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 street_address

  data_type: 'text'
  is_nullable: 1

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "contact_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "street_address",
  { data_type => "text", is_nullable => 1 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contact_id>

=back

=cut

__PACKAGE__->set_primary_key("contact_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<company_id>

=over 4

=item * L</company_id>

=item * L</contact_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint("company_id", ["company_id", "contact_type_id"]);

=head1 RELATIONS

=head2 company_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->belongs_to(
  "company_id",
  "BeerFestDB::ORM::Company",
  { company_id => "company_id" },
);

=head2 contact_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::ContactType>

=cut

__PACKAGE__->belongs_to(
  "contact_type_id",
  "BeerFestDB::ORM::ContactType",
  { contact_type_id => "contact_type_id" },
);

=head2 country_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Country>

=cut

__PACKAGE__->belongs_to(
  "country_id",
  "BeerFestDB::ORM::Country",
  { country_id => "country_id" },
);

=head2 telephones

Type: has_many

Related object: L<BeerFestDB::ORM::Telephone>

=cut

__PACKAGE__->has_many(
  "telephones",
  "BeerFestDB::ORM::Telephone",
  { "foreign.contact_id" => "self.contact_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-20 17:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qWfX5HWovLakCr2ZPkn8Qw


# You can replace this text with custom content, and it will be preserved on regeneration
sub repr {
    my ( $self ) = @_; return sprintf("%s: %s",
				      $self->company_id->repr(),
				      $self->contact_type_id->repr());
}

1;
