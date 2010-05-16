package BeerFestDB::Web::Controller::Bar;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Bar - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Bar in Bar.');
}

# FIXME we want a means to list beers on a bar, and edit this where necessary.

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
