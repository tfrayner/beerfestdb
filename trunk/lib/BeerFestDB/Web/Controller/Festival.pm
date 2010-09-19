package BeerFestDB::Web::Controller::Festival;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

BeerFestDB::Web::Controller::Festival - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Just redirect to the main festival grid for now.
    $c->response->redirect($c->uri_for('grid'));
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    # Maps View onto Model columns.
    my %mv_map = (        
        festival_id     => 'festival_id',
        year            => 'year',
        name            => 'name',
        description     => 'description',
        fst_start_date  => 'fst_start_date',
        fst_end_date    => 'fst_end_date',
    );

    my @festivals;
    while ( my $obj = $rs->next() ) {
        my %fest_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @festivals, \%fest_info;
    }

    $c->stash->{ 'objects' } = \@festivals;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    foreach my $rec ( @{ $data } ) {
        eval {
            $rs->update_or_create( $rec );
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to save one or more festivals to database: $@";
        }
    }

    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

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
            $c->stash->{error} = "Unable to delete one or more festivals: $@";
        }
    }

    $c->detach( $c->view( 'JSON' ) );
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c ) = @_;

}

=head2 view

=cut

sub view : Local { 

    my ($self, $c, $id) = @_;

    my $object = $c->model('DB::Festival')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: Festival not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }
    my @categories = $c->model('DB::ProductCategory')->all();
    my @bars       = $c->model('DB::Bar')->search({ 'festival_id' => $id });
    my @stillages  = $c->model('DB::StillageLocation')->search({ 'festival_id' => $id });

    $c->stash->{object}     = $object;
    $c->stash->{categories} = \@categories;
    $c->stash->{bars}       = \@bars;
    $c->stash->{stillages}  = \@stillages;

    return;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
