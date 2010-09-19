package BeerFestDB::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

BeerFestDB::Web::Controller::Root - Root Controller for BeerFestDB::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private { 
    my ( $self, $c ) = @_; 
    $c->response->status('404'); 
    $c->stash->{template} = 'not_found.tt2'; 
} 

=head2 index

=cut

sub index : Private {};

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
