package BeerFestDB::Web::Controller::Product;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

BeerFestDB::Web::Controller::Product - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Product in Product.');
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );
    my @products;
    while ( my $prod = $rs->next ) {
        push( @products, {
            product_id  => $prod->product_id,
            name        => $prod->name,
            description => $prod->description,
            comment     => $prod->comment,
        } );
    }

    $c->stash->{ 'products' } = \@products;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    for my $rec ( @{ $data } ) {
        $rs->update_or_create( $rec );
    }

    $c->detach( $c->view( 'JSON' ) );

    return;
}



=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
