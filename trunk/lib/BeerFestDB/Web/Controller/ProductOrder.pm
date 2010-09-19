package BeerFestDB::Web::Controller::ProductOrder;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::ProductOrder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::ProductOrder in ProductOrder.');
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    # This method is intended to generally work with a defined
    # festival_id; however, since it was based on the equivalent
    # action in Product, it can in principle support a listing of all
    # orders ever.

    # It's not yet clear whether we need to split orders by category
    # for our own purposes, but we provide that option for more general use.
    my ( $cond, $attrs );
    if ( defined $category_id ) {
        $cond  = { 'product_id.product_category_id' => $category_id };
        $attrs = { join => { product_id => 'product_category_id' } };
    }

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = 'Festival not found.';
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->search_related('product_orders', $cond, $attrs)
    }
    else {
        $rs = $c->model( 'DB::ProductOrder' )->search_rs( $cond, $attrs );
    }

    # Maps View onto Model columns.
    my %mv_map = (
        product_order_id  => 'product_order_id',
        product_id        => 'product_id',
        distributor_id    => 'distributor_company_id',
        container_size_id => 'container_size_id',
        cask_count        => 'cask_count',
        currency_id       => 'currency_id',
        price             => 'advertised_price',
        is_final          => 'is_final',
        comment           => 'comment',
    );

    my @orders;
    while ( my $obj = $rs->next ) {
        my %order_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @orders, \%order_info;
    }

    $c->stash->{ 'objects' } = \@orders;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    foreach my $rec ( @{ $data } ) {
        
        eval {
            my $order = $rs->update_or_create( $rec );
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to save one or more orders to database: $@";
        }
    }
    
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::ProductOrder' );

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
            $c->stash->{error} = "Unable to delete one or more orders: $@";
        }
    }

    $c->detach( $c->view( 'JSON' ) );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c, $festival_id, $category_id ) = @_;

    if ( defined $festival_id ) {
        my $festival = $c->model('DB::Festival')->find($festival_id);
        unless ( $festival ) {
            $c->flash->{error} = "Error: Festival not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{festival} = $festival;
    }

    # It's not clear yet whether splitting orders by category is
    # actually desirable.
    if ( defined $category_id ) {
        my $category = $c->model('DB::ProductCategory')->find($category_id);
        unless ( $category ) {
            $c->flash->{error} = "Error: Product category not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{category} = $category;
    }
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
