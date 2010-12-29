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
        stillage_location_id => 'stillage_location_id',
        festival_id          => 'festival_id',
        description          => 'description',
    });
}

# FIXME this method is likely to end up as redundant. Instead, we'll
# support this via a multi-tab festival page with a grid for stillage
# locations
sub add_to_festival : Local {

    my ( $self, $c, $festival_id ) = @_;

    $c->stash()->{festival_id} = $festival_id;
}

sub list : Local {

    my ( $self, $c, $festival_id ) = @_;

    my ( $rs, $festival );
    if ( defined $festival_id ) {
        $festival = $c->model( 'DB::Festival' )->find({festival_id => $festival_id});
        unless ( $festival ) {
            $c->stash->{error} = qq{Festival ID "$festival_id" not found.};
            $c->res->redirect( $c->uri_for('/default') );
            $c->detach();
        }
        $rs = $festival->stillage_locations()
    }
    else {
        die('Error: festival_id not defined.');
    }

    $self->generate_json_and_detach( $c, $rs );
}

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::StillageLocation');

    $self->write_to_resultset( $c, $rs );
}

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::StillageLocation');

    $self->delete_from_resultset( $c, $rs );
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

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
