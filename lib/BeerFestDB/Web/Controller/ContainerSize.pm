package BeerFestDB::Web::Controller::ContainerSize;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ContainerSize - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ContainerSize' );

    # Maps View onto Model columns.
    my %mv_map = (        
        container_size_id => 'container_size_id',
        volume            => 'container_volume',
        measure_id        => 'container_measure_id',
        description       => 'container_description',
    );

    my @sizes;
    while ( my $obj = $rs->next() ) {
        my %size_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @sizes, \%size_info;
    }

    $c->stash->{ 'objects' } = \@sizes;
    $c->detach( $c->view( 'JSON' ) );

    return;
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
