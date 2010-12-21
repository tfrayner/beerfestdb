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
        my %obj_info = map { $_ => $self->_view_to_model($_, $obj) } keys %mv_map;
        push @objects, \%obj_info;
    }

    $c->stash->{ 'objects' } = \@objects;
    $c->detach( $c->view( 'JSON' ) );
}

sub _view_to_model : Private {

    # Method using a JSON view object attribute name (from
    # model_view_map), to retrieve the appropriate model attribute
    # from a DBIx::Class::Row object.
    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    $lookup ||= $self->model_view_map()->{ $view_key } || $view_key;

    if ( ref $lookup eq 'HASH' ) {

        # Hashrefs should contain relationship => column style
        # structures (this is recursive).
        my @children;
        foreach my $relation ( keys %$lookup ) {
            push @children,
                $self->_view_to_model( $lookup->{$relation},
                                       $dbrow->$relation,
                                       $lookup->{$relation} );
        }

        if ( scalar @children > 1 ) {
            confess("Error: Multiple keys in model_view_map"
                        . " relationships are not supported.");
        }
        elsif ( scalar @children < 1 ) {
            confess("Error: model_view_map contains empty hashrefs.");
        }
        return $children[0];
    }
    else {
        return $dbrow->get_column( $lookup );
    }
}

sub _build_db_obj : Private {

    my ( $self, $rec, $c, $rs, $mv_map ) = @_;

    # Passed a JSON record nested hashref, Catalyst context and the
    # appropriate DBIC::ResultSet object, create database objects
    # recursively (depth first).

    my %dbobj_info;

    $mv_map ||= $self->model_view_map();
    
    foreach my $view_key (keys %$rec) {

        # There's a strong risk of key collision from an upper
        # recursion into this one here; to fix this, we have to manage
        # the $mv_map hashref as part of that recursion.
        my $lookup ||= $mv_map->{ $view_key } || $view_key;

        if ( ref $lookup eq 'HASH' ) {
            my @children = keys %$lookup;

            if ( scalar @children > 1 ) {
                confess("Error: Multiple keys in model_view_map"
                            . " relationships are not supported.");
            }
            elsif ( scalar @children < 1 ) {
                confess("Error: model_view_map contains empty hashrefs.");
            }

            my $rel = $children[0];

            my $next_attr = $lookup->{ $rel };
            my $next_rs   = $rs->result_source()->related_source( $rel )->resultset();
            my $next_rec  = { $next_attr => $rec->{ $view_key } };

            $dbobj_info{ $rel } = $self->_build_db_obj( $next_rec, $c, $next_rs, {} );
        }
        else {
            $dbobj_info{ $lookup } = $rec->{ $view_key };
        }
    }

    my $dbobj;
    eval {
        $dbobj = $rs->update_or_create( \%dbobj_info );
    };
    if ($@) {
        $c->response->status('403');  # Forbidden

        # N.B. flash_to_stash doesn't seem to work for JSON views.
        $c->stash->{error} = "Unable to save one or more objects to database: $@";
    }

    return( $dbobj );
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

    foreach my $rec ( @{ $data } ) {
        my $dbobj = $self->_build_db_obj( $rec, $c, $rs );
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
