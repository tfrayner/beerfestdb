package BeerFestDB::Web::Controller::Product;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

use Storable qw(dclone);

=head1 NAME

BeerFestDB::Web::Controller::Product - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        product_id       => 'product_id',
        company_id       => 'company_id',
        name             => 'name',
        description      => 'description',
        comment          => 'comment',
        product_style_id => 'product_style_id',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {

    # Listing of product types linking to grid views for each.
    my ( $self, $c ) = @_;

    my @categories = $c->model('DB::ProductCategory')->all(); 

    $c->stash->{categories} = \@categories;
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $category_id, $festival_id ) = @_;

    # This is just a product listing at this stage; one row per
    # product (per supplier). If festival_id is supplied then the list
    # is filtered based on which products are at a given
    # festival. Note that this listing is therefore swinging between
    # the virtual (no $festival_id) and the concrete ($festival_id,
    # linking via cask and gyle). At some point it may be wiser to
    # split this method, e.g. building on the FestivalProduct class instead.

    my ( $rs, $festival );
    my $cond = defined $category_id ? { product_category_id => $category_id } : {};
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related('festival_products')
                       ->search_related('product_id', $cond);
    }
    else {
        $rs = $c->model( 'DB::Product' )->search_rs($cond);
    }
    
    $self->generate_json_and_detach( $c, $rs );
}

=head2 list_by_company

=cut

sub list_by_company : Local {

    # Sketched-out method to retrieve all products produced by a given
    # company. It seems likely that this will not be immediately
    # useful; instead we'll probably just filter on our productStore
    # in the javascript. This has the benefit of pre-filtering by
    # category in the list method.
    my ( $self, $c, $company_id ) = @_;

    my $rs;
    if ( defined $company_id ) {
        $rs = $c->model( 'DB::Product' )->search_rs( { company_id => $company_id } );
    }
    else {
        $rs = $c->model( 'DB::Product' );  # FIXME is this actually needed?
    }

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Product' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $category_id, $festival_id ) = @_;

    if ( defined $festival_id ) {
        my $festival = $c->model('DB::Festival')->find($festival_id);
        unless ( $festival ) {
            $c->flash->{error} = "Error: Festival not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{festival} = $festival;
    }

    my $category = $c->model('DB::ProductCategory')->find($category_id);
    unless ( $category ) {
        $c->flash->{error} = "Error: Product category not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    $c->stash->{category} = $category;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
