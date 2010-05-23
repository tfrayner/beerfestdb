package BeerFestDB::ORM::Telephone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Telephone

=cut

__PACKAGE__->table("telephone");

=head1 ACCESSORS

=head2 telephone_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 telephone_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 interational_code

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 area_code

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 telephone

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 extension

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "telephone_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "telephone_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "interational_code",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "area_code",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "telephone",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "extension",
  { data_type => "varchar", is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("telephone_id");

=head1 RELATIONS

=head2 contact_telephones

Type: has_many

Related object: L<BeerFestDB::ORM::ContactTelephone>

=cut

__PACKAGE__->has_many(
  "contact_telephones",
  "BeerFestDB::ORM::ContactTelephone",
  { "foreign.telephone_id" => "self.telephone_id" },
  {},
);

=head2 telephone_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::TelephoneType>

=cut

__PACKAGE__->belongs_to(
  "telephone_type_id",
  "BeerFestDB::ORM::TelephoneType",
  { telephone_type_id => "telephone_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2C2CeS530lJGGUcYYEtXOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
