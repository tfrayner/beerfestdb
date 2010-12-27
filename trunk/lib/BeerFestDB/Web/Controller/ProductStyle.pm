package BeerFestDB::Web::Controller::ProductStyle;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductStyle - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_style_id      => 'product_style_id',
        product_category_id   => 'product_category_id',
        description           => 'description',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductStyle' );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_category

=cut

sub list_by_category : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::ProductStyle' )->search({ product_category_id => $id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductStyle' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductStyle' );

    $self->delete_from_resultset( $c, $rs );
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
