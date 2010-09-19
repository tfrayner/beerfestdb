package BeerFestDB::Web::Controller::StillageLocation;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::StillageLocation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
    });
}

# FIXME we need a means to edit and view casks on the stillage.

sub add_to_festival : Local {

    my ( $self, $c, $festival_id ) = @_;

    $c->stash()->{festival_id} = $festival_id;
}

sub submit : Local {

    my ( $self, $c ) = @_;

    eval {
        $c->model('DB::StillageLocation')->update_or_create(
            $c->request->params,
        );
    };
    if ($@) {
        $c->response->status('403');  # Forbidden

        # N.B. flash_to_stash doesn't seem to work for JSON views.
        $c->stash->{error} = "Unable to save one or more objects to database: $@";
    }

    return;
}

sub grid : Local {

    my ( $self, $c, $stillage_id ) = @_;

    if ( defined $stillage_id ) {
        my $stillage = $c->model('DB::StillageLocation')->find($stillage_id);
        unless ( $stillage ) {
            $c->flash->{error} = "Error: Stillage not found.";
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();        
        }
        $c->stash->{stillage} = $stillage;
    }

    return;
}

sub list_casks : Local {

    my ( $self, $c, $id ) = @_;

    my $rs = $c->model( 'DB::Cask' )->search({ stillage_location_id => $id });
    my @casks;
    while ( my $cask = $rs->next ) {
        push( @casks, {
            cask_id     => $cask->cask_id,
            product     => $cask->gyle_id->product_id->name,
        } );
    }

    $c->stash->{ 'objects' } = \@casks;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
