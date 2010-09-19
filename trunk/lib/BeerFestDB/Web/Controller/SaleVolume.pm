package BeerFestDB::Web::Controller::SaleVolume;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::SaleVolume - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::SaleVolume' );

    # Maps View onto Model columns.
    my %mv_map = (
        sale_volume_id       => 'sale_volume_id',
        container_measure_id => 'container_measure_id',
        description          => 'sale_volume_description',
        volume               => 'volume',
    );

    my @volumes;
    while ( my $obj = $rs->next() ) {
        my %vol_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @volumes, \%vol_info;
    }

    $c->stash->{ 'objects' } = \@volumes;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
