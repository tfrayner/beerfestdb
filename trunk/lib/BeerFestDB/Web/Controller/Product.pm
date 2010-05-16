package BeerFestDB::Web::Controller::Product;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Storable qw(dclone);

=head1 NAME

BeerFestDB::Web::Controller::Product - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


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
    # linking via cask and gyle).

    my ( $product_rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $product_rs = $festival->search_related('festival_products')
                               ->search_related('product_id',
                                                { product_category_id => $category_id });
    }
    else {
        $product_rs = $c->model( 'DB::Product' )->search_rs({product_category_id => $category_id});
    }
    
    my @products;
    while ( my $prod = $product_rs->next ) {
        my $style_id;
        if ( my $style = $prod->product_style_id ) {
            $style_id = $style->product_style_id;
        }

        my %prod_info = (
            product_id  => $prod->product_id,
            name        => $prod->name,
            description => $prod->description,
            comment     => $prod->comment,
            product_style_id => $style_id,
        );

        # Retrieve supplier info. Note that the prefetch is critical here.
        my @suppliers;
        if ( $festival ) {

            # For a given festival the suppliers list is linked via
            # cask, i.e. is a concrete representation of what has been
            # delivered.
            @suppliers =
                $prod->search_related('company_products',
                                      { 'casks.festival_id' => $festival->id },
                                      {
                                          prefetch => {
                                              company_id => {
                                                  gyles => { casks => 'festival_id' }
                                              }
                                          },
                                          join => {
                                              company_id => {
                                                  gyles => { casks => 'festival_id' },
                                              }
                                          },
                                      }
                                  );
        }
        else {

            # For the more general case we just take all possible
            # suppliers and list them.
            @suppliers = $prod->producers()
        }

        foreach my $supp ( @suppliers ) {
            my $i = dclone( \%prod_info );
            $i->{company_id} = $supp->id();
            push( @products, $i );
        }
    }

    $c->stash->{ 'objects' } = \@products;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 submit

=cut

sub submit : Local {  # FIXME FIXME FIXME this method has been largely superceded in the new UI design.

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

            # FIXME at the moment we just assume at least a single cask, for simplicity's sake.
            my $cask = $c->model( 'DB::Cask' )->find_or_create({
                festival_id        => ,
                gyle_id            => ,
            });
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

sub delete : Local { # FIXME FIXME FIXME doesn't this need reviewing?
                     # how often do we actually want to delete
                     # products anyway? Casks, yes; Products, no.

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
