package BeerFestDB::ORM::FestivalEntry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::FestivalEntry

=cut

__PACKAGE__->table("festival_entry");

=head1 ACCESSORS

=head2 festival_opening_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 festival_entry_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 currency_code

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 3

=head2 price

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "festival_opening_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "festival_entry_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "currency_code",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 3 },
  "price",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("festival_opening_id", "festival_entry_type_id");

=head1 RELATIONS

=head2 festival_opening_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::FestivalOpening>

=cut

__PACKAGE__->belongs_to(
  "festival_opening_id",
  "BeerFestDB::ORM::FestivalOpening",
  { festival_opening_id => "festival_opening_id" },
);

=head2 festival_entry_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::FestivalEntryType>

=cut

__PACKAGE__->belongs_to(
  "festival_entry_type_id",
  "BeerFestDB::ORM::FestivalEntryType",
  { "festival_entry_type_id" => "festival_entry_type_id" },
);

=head2 currency_code

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_code",
  "BeerFestDB::ORM::Currency",
  { currency_code => "currency_code" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g6P2LcI2PlcSNZcIDJVE5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
