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

    my ( $self, $c, $category_id ) = @_;

    my $rs = $c->model( 'DB::Product' )->search({ product_category_id => $category_id });
    my @products;
    while ( my $prod = $rs->next ) {
        my $name = sprintf(qq{<a href="%s">%s</a>}, $c->uri_for('view', $prod->product_id), $prod->name);
        push( @products, {
            product_id  => $prod->product_id,
            name        => $prod->name,
            description => $prod->description,
            comment     => $prod->comment,
        } );
    }

    $c->stash->{ 'objects' } = \@products;
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

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    for my $id ( @{ $data } ) {
        my $rec = $rs->find($id);
        eval {
            $rec->delete() if $rec;
        };
        if ($@) {
            $c->flash->{error} = "Problem deleting selected object(s).";
        }
    }

    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $festival = $c->model('DB::Festival')->find($festival_id);
    unless ( $festival ) {
        $c->flash->{error} = "Error: Festival not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{festival} = $festival;

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = "Error: Product category not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;

    my @styles = $category->product_styles();
    $c->stash->{styles} = \@styles;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
