package BeerFestDB::Web::Controller::ProductStyle;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductStyle - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductStyle' );

    # Maps View onto Model columns.
    my %mv_map = (
        product_style_id      => 'product_style_id',
        product_category_id   => 'product_category_id',
        description           => 'description',
    );

    my @styles;
    while ( my $obj = $rs->next() ) {
        my %style_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @styles, \%style_info;
    }

    $c->stash->{ 'objects' } = \@styles;
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
