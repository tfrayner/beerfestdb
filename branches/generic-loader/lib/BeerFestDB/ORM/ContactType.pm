package BeerFestDB::ORM::ContactType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ContactType

=cut

__PACKAGE__->table("contact_type");

=head1 ACCESSORS

=head2 contact_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 contact_type_description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "contact_type_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "contact_type_description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("contact_type_id");
__PACKAGE__->add_unique_constraint("contact_type_description", ["contact_type_description"]);

=head1 RELATIONS

=head2 contacts

Type: has_many

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "BeerFestDB::ORM::Contact",
  { "foreign.contact_type_id" => "self.contact_type_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QoUZ8VDxPG+AkysHURY+YA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
