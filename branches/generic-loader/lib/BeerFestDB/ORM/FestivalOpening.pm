package BeerFestDB::ORM::FestivalOpening;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::FestivalOpening

=cut

__PACKAGE__->table("festival_opening");

=head1 ACCESSORS

=head2 festival_opening_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 festival_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 op_start_date

  data_type: 'datetime'
  is_nullable: 0

=head2 op_end_date

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "festival_opening_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "festival_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "op_start_date",
  { data_type => "datetime", is_nullable => 0 },
  "op_end_date",
  { data_type => "datetime", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("festival_opening_id");

=head1 RELATIONS

=head2 festival_entries

Type: has_many

Related object: L<BeerFestDB::ORM::FestivalEntry>

=cut

__PACKAGE__->has_many(
  "festival_entries",
  "BeerFestDB::ORM::FestivalEntry",
  { "foreign.festival_opening_id" => "self.festival_opening_id" },
  {},
);

=head2 festival_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Festival>

=cut

__PACKAGE__->belongs_to(
  "festival_id",
  "BeerFestDB::ORM::Festival",
  { festival_id => "festival_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XrpBKoJzlFWr/OkxZiKypA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
