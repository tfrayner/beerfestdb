package BeerFestDB::Web::Controller::SaleVolume;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::SaleVolume - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        sale_volume_id       => 'sale_volume_id',
        container_measure_id => 'container_measure_id',
        description          => 'sale_volume_description',
        volume               => 'volume',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::SaleVolume' );

    $self->generate_json_and_detach( $c, $rs );
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
