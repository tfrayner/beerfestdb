use utf8;
package BeerFestDB::ORM::FestivalEntryType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::FestivalEntryType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<festival_entry_type>

=cut

__PACKAGE__->table("festival_entry_type");

=head1 ACCESSORS

=head2 festival_entry_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "festival_entry_type_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</festival_entry_type_id>

=back

=cut

__PACKAGE__->set_primary_key("festival_entry_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 festival_entries

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalEntry>

=cut

__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  {
    "foreign.festival_entry_type_id" => "self.festival_entry_type_id",
  },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cstqLqZIn0j7Ld4lk/AxGA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
