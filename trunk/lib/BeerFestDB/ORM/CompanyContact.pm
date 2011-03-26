package BeerFestDB::ORM::CompanyContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::CompanyContact

=cut

__PACKAGE__->table("company_contact");

=head1 ACCESSORS

=head2 company_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "company_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("company_id", "contact_id");

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

=head2 contact_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact_id",
  "BeerFestDB::ORM::Contact",
  { contact_id => "contact_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-26 11:41:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:86h39YdOpSwD+QgQdJLU+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
