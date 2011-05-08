package BeerFestDB::ORM::ProgrammeNotesView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ProgrammeNotesView

=cut

__PACKAGE__->table("programme_notes_view");

=head1 ACCESSORS

=head2 festival

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 category

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 brewer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 year_established

  data_type: 'integer'
  is_nullable: 1

=head2 beer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 tasting_notes

  data_type: 'text'
  is_nullable: 1

=head2 style

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "festival",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "category",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "brewer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "year_established",
  { data_type => "integer", is_nullable => 1 },
  "beer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "tasting_notes",
  { data_type => "text", is_nullable => 1 },
  "style",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-08 17:17:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P5Ju8MIYspAndcyGZbViCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
