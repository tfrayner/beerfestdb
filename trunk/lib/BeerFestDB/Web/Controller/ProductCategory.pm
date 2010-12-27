package BeerFestDB::Web::Controller::ProductCategory;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductCategory - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_category_id   => 'product_category_id',
        description           => 'description',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my @categories = $c->model('DB::ProductCategory')->all(); 

    $c->stash->{categories} = \@categories;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductCategory' );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $category_id ) = @_;

    if ( defined $category_id ) {
        my $category = $c->model('DB::ProductCategory')->find($category_id);
        unless ( $category ) {
            $c->flash->{error} = "Error: Product Category not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{category} = $category;
    }
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductCategory' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductCategory' );

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
