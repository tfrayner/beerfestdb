package BeerFestDB::ORM::Company;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::Company

=cut

__PACKAGE__->table("company");

=head1 ACCESSORS

=head2 company_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 loc_desc

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 year_founded

  data_type: 'year'
  is_nullable: 1

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "company_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "loc_desc",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "year_founded",
  { data_type => "year", is_nullable => 1 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("company_id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 company_contacts

Type: has_many

Related object: L<BeerFestDB::ORM::CompanyContact>

=cut

__PACKAGE__->has_many(
  "company_contacts",
  "BeerFestDB::ORM::CompanyContact",
  { "foreign.company_id" => "self.company_id" },
  {},
);

=head2 gyles

Type: has_many

Related object: L<BeerFestDB::ORM::Gyle>

=cut

__PACKAGE__->has_many(
  "gyles",
  "BeerFestDB::ORM::Gyle",
  { "foreign.company_id" => "self.company_id" },
  {},
);

=head2 products

Type: has_many

Related object: L<BeerFestDB::ORM::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "BeerFestDB::ORM::Product",
  { "foreign.company_id" => "self.company_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nZmDs79X8p/IyiDlbxw0Pg


# You can replace this text with custom content, and it will be preserved on regeneration

1;
