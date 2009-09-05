package BeerFestDB::Web::Model::DB;

use strict;
use warnings;

use parent 'Catalyst::Model::DBIC::Schema';

# Database connection params are set in the main config file.
__PACKAGE__->config(
    schema_class => 'BeerFestDB::ORM',
);

=head1 NAME

BeerFestDB::Web::Model::DB - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
