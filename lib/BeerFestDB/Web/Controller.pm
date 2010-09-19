package BeerFestDB::Web::Controller;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

has 'model_view_map' => ( is  => 'rw',
                          isa => 'HashRef' );

=head1 NAME

BeerFestDB::Web::Controller - Base class for BeerFestDB Controllers

=head1 DESCRIPTION

Catalyst Controller base class.

=head1 METHODS

=head2 generate_json_and_detach

Passed a resultset object, maps it onto the view JSON objects and detaches.

=cut

sub generate_json_and_detach : Private {

    my ( $self, $c, $rs ) = @_;

    # Maps View onto Model columns.
    my %mv_map = %{ $self->model_view_map() };

    my @objects;
    while ( my $obj = $rs->next ) {
        my %obj_info = map { $_ => $obj->get_column( $mv_map{$_} || $_ ) } keys %mv_map;
        push @objects, \%obj_info;
    }

    $c->stash->{ 'objects' } = \@objects;
    $c->detach( $c->view( 'JSON' ) );
}

=head2 write_to_resultset

Passed a resultset and a context object, map the changes in the
context back to the database column names, and attempt to write it to
the database.

=cut

sub write_to_resultset : Private {

    my ( $self, $c, $rs ) = @_;

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    # Quick-and-dirty, if there are duplicate values in the original
    # hash they'll be clobbered here.
    my %mv_map = reverse %{ $self->model_view_map };

    foreach my $rec ( @{ $data } ) {

        my $dbrec = { map { ( $mv_map{$_} || $_ ) => $rec->{$_} } keys %$rec };

        eval {
            my $order = $rs->update_or_create( $dbrec );
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to save one or more objects to database: $@";
        }
    }
    
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 delete_from_resultset

Passed a resultset and a context object, delete the appropriate
objects from the database.

=cut

sub delete_from_resultset : Private {

    my ( $self, $c, $rs ) = @_;

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
