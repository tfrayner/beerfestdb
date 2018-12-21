use utf8;
package BeerFestDB::ORM::OrderSummaryView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::OrderSummaryView - VIEW

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<order_summary_view>

=cut

__PACKAGE__->table("order_summary_view");

=head1 ACCESSORS

=head2 festival

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 category

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 brewery

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 beer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 style

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sale_or_return

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 3

=head2 abv

  data_type: 'decimal'
  is_nullable: 1
  size: [3,1]

=head2 kils

  data_type: 'decimal'
  is_nullable: 1
  size: [43,1]

=cut

__PACKAGE__->add_columns(
  "festival",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "category",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "brewery",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "beer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "style",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sale_or_return",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 3 },
  "abv",
  { data_type => "decimal", is_nullable => 1, size => [3, 1] },
  "kils",
  { data_type => "decimal", is_nullable => 1, size => [43, 1] },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-17 16:29:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Nk0ZNRnVjynoP8sC+bXCOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
