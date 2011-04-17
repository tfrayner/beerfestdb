package BeerFestDB::ORM::TelephoneType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::TelephoneType

=cut

__PACKAGE__->table("telephone_type");

=head1 ACCESSORS

=head2 telephone_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "telephone_type_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("telephone_type_id");
__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 telephones

Type: has_many

Related object: L<BeerFestDB::ORM::Telephone>

=cut

__PACKAGE__->has_many(
  "telephones",
  "BeerFestDB::ORM::Telephone",
  { "foreign.telephone_type_id" => "self.telephone_type_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UZWUPqQfIvzPqO15QUozQA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
