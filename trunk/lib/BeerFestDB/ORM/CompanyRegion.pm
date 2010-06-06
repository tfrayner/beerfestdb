package BeerFestDB::ORM::CompanyRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::CompanyRegion

=cut

__PACKAGE__->table("company_region");

=head1 ACCESSORS

=head2 company_region_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "company_region_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("company_region_id");
__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 companies

Type: has_many

Related object: L<BeerFestDB::ORM::Company>

=cut

__PACKAGE__->has_many(
  "companies",
  "BeerFestDB::ORM::Company",
  { "foreign.company_region_id" => "self.company_region_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-05 23:21:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l87XkixSW4HIxMZ/TTh/1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
