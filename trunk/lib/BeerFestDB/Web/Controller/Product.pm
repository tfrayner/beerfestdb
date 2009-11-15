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

    my ( $self, $c, $category_id, $festival_id ) = @_;

    my $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
    unless ( $festival ) {
        $c->response->status('403');  # Forbidden
        $c->stash->{error} = 'Festival not found.';
    }
    my $gyle_rs = $festival->casks()->search_related('gyle_id');
    
    my @products;
    while ( my $gyle = $gyle_rs->next ) {

        my $prod_rs = $gyle->search_related('product_id',
                                            { product_category_id => $category_id });

        while ( my $prod = $prod_rs->next ) {
            my $style_id;
            if ( my $style = $prod->product_style_id ) {
                $style_id = $style->product_style_id;
            }

            # This is many-to-many; generate one row per gyle. Add in
            # gyle numbers; we will set this as non-editable, just a
            # visual guide for reassigning gyles between brewers.

            push( @products, {
                product_id  => $prod->product_id,
                gyle        => $gyle->external_reference,
                company_id  => $gyle->company_id->company_id,
                name        => $prod->name,
                description => $prod->description,
                comment     => $prod->comment,
                product_style_id => $style_id,
            } );
        }
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

    foreach my $rec ( @{ $data } ) {

        my ( $brewer_id, $gyle_id );
        if ( exists $rec->{'company_id'} ) {
            $brewer_id = $rec->{'company_id'};
            delete($rec->{'company_id'});
            $gyle_id = $rec->{'gyle'};
        }
        delete($rec->{'gyle'});

        # FIXME we need to link new products up with their respective
        # festival. Best way to do this might be to ask for no. of
        # casks upon creation of new record (or, more specifically,
        # new attachment of record to festival). This figure would
        # then be changeable on the view pages for each product.
        eval {
            my $prod = $rs->update_or_create( $rec );

            if ( defined $gyle_id && defined $brewer_id ) {
                foreach my $gyle ( $prod->gyles({ external_reference => $gyle_id }) ) {
                    $gyle->set_column( 'company_id', $brewer_id );
                    $gyle->update();
                }
            }
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = 'Unable to save one or more products to database';
        }
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

    foreach my $id ( @{ $data } ) {
        my $rec = $rs->find($id);
        eval {
            $rec->delete() if $rec;
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = 'Unable to delete one or more products';
        }
    }

    $c->detach( $c->view( 'JSON' ) );
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

    my @brewers = $c->model('DB::Company')->all();
    $c->stash->{brewers} = \@brewers;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
