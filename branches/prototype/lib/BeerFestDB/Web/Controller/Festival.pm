package BeerFestDB::Web::Controller::Festival;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

BeerFestDB::Web::Controller::Festival - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Festival in Festival.');
}

=head2 list

=cut

sub list : Local { 
    my ($self, $c) = @_; 
    my @objects = $c->model('DB::Festival')->all(); 
    $c->stash->{objects} = \@objects;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
