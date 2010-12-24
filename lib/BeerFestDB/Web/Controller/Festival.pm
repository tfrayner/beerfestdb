package BeerFestDB::Web::Controller::Festival;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Festival - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        festival_id     => 'festival_id',
        year            => 'year',
        name            => 'name',
        description     => 'description',
        fst_start_date  => 'fst_start_date',
        fst_end_date    => 'fst_end_date',
    });
}

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

    $self->generate_json_and_detach( $c, $rs );
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Festival' );

    $self->delete_from_resultset( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {}

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