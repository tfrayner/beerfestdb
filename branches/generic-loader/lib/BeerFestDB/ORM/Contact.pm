package BeerFestDB::ORM::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Contact

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contact_id

  data_type: 'integer'
  is_auto_increment: 1
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

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 country_code_iso2

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 1
  size: 2

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "contact_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "contact_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "street_address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "country_code_iso2",
  { data_type => "char", is_foreign_key => 1, is_nullable => 1, size => 2 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("contact_id");

=head1 RELATIONS

=head2 company_contacts

Type: has_many

Related object: L<BeerFestDB::ORM::CompanyContact>

=cut

__PACKAGE__->has_many(
  "company_contacts",
  "BeerFestDB::ORM::CompanyContact",
  { "foreign.contact_id" => "self.contact_id" },
  {},
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

=head2 country_code_iso2

Type: belongs_to

Related object: L<BeerFestDB::ORM::Country>

=cut

__PACKAGE__->belongs_to(
  "country_code_iso2",
  "BeerFestDB::ORM::Country",
  { country_code_iso2 => "country_code_iso2" },
);

=head2 contact_telephones

Type: has_many

Related object: L<BeerFestDB::ORM::ContactTelephone>

=cut

__PACKAGE__->has_many(
  "contact_telephones",
  "BeerFestDB::ORM::ContactTelephone",
  { "foreign.contact_id" => "self.contact_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oqM+5LElDdJMvSl5C8DiYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;