package BeerFestDB::ORM::ContactTelephone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

BeerFestDB::ORM::ContactTelephone

=cut

__PACKAGE__->table("contact_telephone");

=head1 ACCESSORS

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 telephone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "telephone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("contact_id", "telephone_id");

=head1 RELATIONS

=head2 contact_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact_id",
  "BeerFestDB::ORM::Contact",
  { contact_id => "contact_id" },
);

=head2 telephone_id

Type: belongs_to

Related object: L<BeerFestDB::ORM::Telephone>

=cut

__PACKAGE__->belongs_to(
  "telephone_id",
  "BeerFestDB::ORM::Telephone",
  { telephone_id => "telephone_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-05-23 15:30:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CxCYO3Np/X+OXuXO+Bj3ag


# You can replace this text with custom content, and it will be preserved on regeneration
1;
