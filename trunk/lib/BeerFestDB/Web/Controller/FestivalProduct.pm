package BeerFestDB::Web::Controller::FestivalProduct;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::FestivalProduct - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        festival_product_id => 'festival_product_id',
        product_id          => 'product_id',
        festival_id         => 'festival_id',
        sale_price          => 'sale_price',
        sale_currency_id    => 'sale_currency_id',
        sale_volume_id      => 'sale_volume_id',
        company_id          => {
            product_id          => 'company_id',
        },
    });
}

=head2 index

=cut

sub index :Path :Args(0) {

    # Listing of product types linking to grid views for each.
    my ( $self, $c, $festival_id ) = @_;

    my @categories = $c->model('DB::ProductCategory')->all(); 

    $c->stash->{categories} = \@categories;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$festival_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related(
            'festival_products',
            { 'product_id.product_category_id' => $category_id },
            {
                join     => { product_id => 'product_category_id' },
                prefetch => { product_id => 'product_category_id' },
            });
    }
    else {
        die('Error: festival_id not defined.');
    }
    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    my $festival = $c->model('DB::Festival')->find($festival_id);
    unless ( $festival ) {
        $c->flash->{error} = qq{Festival ID "$festival_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{festival} = $festival;

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = qq{Product category ID "$category_id" not found.};
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::FestivalProduct');

    # Structure of objects to be created/updated are stored in the
    # Catalyst context.
    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::FestivalProduct');

    # Database IDs of objects to be deleted are stored in the Catalyst context.
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