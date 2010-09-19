package BeerFestDB::Web::Controller::ContainerSize;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ContainerSize - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        container_size_id => 'container_size_id',
        volume            => 'container_volume',
        measure_id        => 'container_measure_id',
        description       => 'container_description',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ContainerSize' );

    $self->generate_json_and_detach( $c, $rs );
}

=cut

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
