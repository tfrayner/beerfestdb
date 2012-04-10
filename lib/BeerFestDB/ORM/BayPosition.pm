use utf8;
package BeerFestDB::ORM::BayPosition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::BayPosition

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<bay_position>

=cut

__PACKAGE__->table("bay_position");

=head1 ACCESSORS

=head2 bay_position_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "bay_position_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bay_position_id>

=back

=cut

__PACKAGE__->set_primary_key("bay_position_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 casks

Type: has_many

Related object: L<BeerFestDB::ORM::Cask>

=cut

__PACKAGE__->has_many(
  "casks",
  "BeerFestDB::ORM::Cask",
  { "foreign.bay_position_id" => "self.bay_position_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-03-22 16:57:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PO+m7DlgGw6F98xBbZCmKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
