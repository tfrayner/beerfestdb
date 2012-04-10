use utf8;
package BeerFestDB::ORM::FestivalEntry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::FestivalEntry

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<festival_entry>

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

=head2 currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 price

  data_type: 'integer'
  extra: {unsigned => 1}
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
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "price",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</festival_opening_id>

=item * L</festival_entry_type_id>

=back

=cut

__PACKAGE__->set_primary_key("festival_opening_id", "festival_entry_type_id");

=head1 RELATIONS

=head2 currency_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency_id",
  "BeerFestDB::ORM::Currency",
  { currency_id => "currency_id" },
);

=head2 festival_entry_type_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::FestivalEntryType>

=cut

__PACKAGE__->belongs_to(
  "festival_entry_type_id",
  "BeerFestDB::ORM::FestivalEntryType",
  { festival_entry_type_id => "festival_entry_type_id" },
);

=head2 festival_opening_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::FestivalOpening>

=cut

__PACKAGE__->belongs_to(
  "festival_opening_id",
  "BeerFestDB::ORM::FestivalOpening",
  { festival_opening_id => "festival_opening_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ncr8Og+aCpGbvTZRgzskgw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
