use utf8;
package BeerFestDB::ORM::Telephone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Telephone

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<telephone>

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

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 international_code

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 area_code

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 local_number

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
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "international_code",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "area_code",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "local_number",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "extension",
  { data_type => "varchar", is_nullable => 1, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</telephone_id>

=back

=cut

__PACKAGE__->set_primary_key("telephone_id");

=head1 RELATIONS

=head2 contact_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact_id",
  "BeerFestDB::ORM::Contact",
  { contact_id => "contact_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PXnW9lgztl8Jps46A4M0Sg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
