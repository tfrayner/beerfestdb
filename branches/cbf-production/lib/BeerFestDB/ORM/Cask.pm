use utf8;
package BeerFestDB::ORM::Cask;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

BeerFestDB::ORM::Cask

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cask>

=cut

__PACKAGE__->table("cask");

=head1 ACCESSORS

=head2 cask_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gyle_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 external_reference

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 is_vented

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_tapped

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_ready

  data_type: 'tinyint'
  is_nullable: 1

=head2 is_condemned

  data_type: 'tinyint'
  is_nullable: 1

=head2 cask_management_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cask_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gyle_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "external_reference",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "is_vented",
  { data_type => "tinyint", is_nullable => 1 },
  "is_tapped",
  { data_type => "tinyint", is_nullable => 1 },
  "is_ready",
  { data_type => "tinyint", is_nullable => 1 },
  "is_condemned",
  { data_type => "tinyint", is_nullable => 1 },
  "cask_management_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cask_id>

=back

=cut

__PACKAGE__->set_primary_key("cask_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cask_management>

=over 4

=item * L</cask_management_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cask_management", ["cask_management_id"]);

=head1 RELATIONS

=head2 cask_management_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::CaskManagement>

=cut

__PACKAGE__->belongs_to(
  "cask_management_id",
  "BeerFestDB::ORM::CaskManagement",
  { cask_management_id => "cask_management_id" },
);

=head2 cask_measurements

Type: has_many

Related object: L<BeerFestDB::ORM::CaskMeasurement>

=cut

__PACKAGE__->has_many(
  "cask_measurements",
  "BeerFestDB::ORM::CaskMeasurement",
  { "foreign.cask_id" => "self.cask_id" },
  {},
);

=head2 gyle_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Gyle>

=cut

__PACKAGE__->belongs_to("gyle_id", "BeerFestDB::ORM::Gyle", { gyle_id => "gyle_id" });


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-02-26 21:06:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y+14Adm3vxLEzO92uEwj0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
