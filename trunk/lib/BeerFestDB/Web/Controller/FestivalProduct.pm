package BeerFestDB::Web::Controller::FestivalProduct;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::FestivalProduct - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


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

    my ( $self, $c, $category_id, $festival_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
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
    
    # Maps View onto Model columns.
    my %mv_map = (        
        festival_product_id => 'festival_product_id',
        product_id          => 'product_id',
        sale_price          => 'sale_price',
        sale_currency_id    => 'sale_currency_id',
        sale_volume_id      => 'sale_volume_id',
    );

    my @fps;
    while ( my $obj = $rs->next() ) {
        my %fp_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        $fp_info{'company_id'} = $obj->product_id->get_column('company_id');
        push @fps, \%fp_info;
    }

    $c->stash->{ 'objects' } = \@fps;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $category_id, $festival_id ) = @_;

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

    my @currencies = $c->model('DB::Currency')->all();
    $c->stash->{currencies} = \@currencies;

    my @volumes = $c->model('DB::SaleVolume')->all();
    $c->stash->{volumes} = \@volumes;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    die("Sorry - this has not been implemented yet.");
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    die("Sorry - this has not been implemented yet.");
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
