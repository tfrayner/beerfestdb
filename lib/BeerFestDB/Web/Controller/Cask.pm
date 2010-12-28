package BeerFestDB::Web::Controller::Cask;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Cask - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        cask_id           => 'cask_id',
        festival_id       => 'festival_id',
        distributor_id    => 'distributor_company_id',
        container_size_id => 'container_size_id',
        bar_id            => 'bar_id',
        stillage_location_id => 'stillage_location_id',
        currency_id       => 'currency_id',
        price             => 'price',
        gyle_id           => 'gyle_id',
        product_id        => {
            gyle_id  => 'product_id',
        },
        company_id        => {
            gyle_id  => {
                product_id => 'company_id',
            },
        },
        stillage_bay      => 'stillage_bay',
        stillage_x        => 'stillage_x_location',
        stillage_y        => 'stillage_y_location',
        stillage_z        => 'stillage_z_location',
        comment           => 'comment',
        ext_reference     => 'external_reference',
        int_reference     => 'internal_reference',
        is_vented         => 'is_vented',
        is_tapped         => 'is_tapped',
        is_ready          => 'is_ready',
    });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Cask in Cask.');
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
            'casks',
            { 'product_id.product_category_id' => $category_id },
            {
                join     => { gyle_id => { product_id => 'product_category_id' } },
                prefetch => { gyle_id => { product_id => 'product_category_id' } },
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

=head2 list_by_stillage

=cut

sub list_by_stillage : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::Cask' )->search({ stillage_location_id => $id });

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 delete_from_stillage

=cut

sub delete_from_stillage : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Cask' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    foreach my $id ( @{ $data } ) {
        my $rec = $rs->find($id);
        eval {
            $rec->set_column('stillage_location_id', undef) if $rec;
            $rec->update();
        };
        if ($@) {
            $c->response->status('403');  # Forbidden
            
            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to delete one or more objects: $@";
        }
    }

    $c->detach( $c->view( 'JSON' ) );
}


=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
