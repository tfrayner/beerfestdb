package BeerFestDB::Web::Controller;
use Moose;
use namespace::autoclean;

use List::Util qw(first);

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

    my ( $self, $rec, $c, $rs, $mv_map, $no_update ) = @_;

    # Passed a JSON record nested hashref, Catalyst context and the
    # appropriate DBIC::ResultSet object, create database objects
    # recursively (depth first).
    $mv_map ||= $self->model_view_map();

    # Firstly, find or create our top-level object. Don't insert a new
    # object yet, since it won't have all the requisite information.
    my %dbobj_info;
    my @primary_cols = $rs->result_source()->primary_columns();
    foreach my $pk ( @primary_cols ) {
        my $value = $rec->{ $pk };
        if ( defined $value ) {
            $dbobj_info{ $pk } = $value;
        }
    }
    my $dbobj = $rs->find_or_new( \%dbobj_info );

    my @hashrefs;

    # Secondly, deal with simple table-based attributes.
    VIEW_KEY:
    foreach my $view_key (keys %$rec) {

        # Skip primary columns; we've already dealt with them.
        next VIEW_KEY if ( first { $view_key eq $_ } @primary_cols );

        # There's a strong risk of key collision from an upper
        # recursion into this one here; to fix this, we have to manage
        # the $mv_map hashref as part of that recursion.
        my $lookup ||= $mv_map->{ $view_key } || $view_key;

        if ( ref $lookup eq 'HASH' ) {
            push @hashrefs, $view_key;
        }
        else {
            my $dbval = $rec->{ $view_key };

            # For some reason these don't want to autoconvert, so we do this manually.
            if ( UNIVERSAL::isa($dbval, 'JSON::PP::Boolean') ) {
                $dbval = $dbval ? 1 : 0;
            }

            $dbobj->set_column( $lookup, $dbval );
        }
    }

    # Thirdly, we handle the relationships.
    foreach my $view_key (@hashrefs) {

        my $lookup ||= $mv_map->{ $view_key } || $view_key;
        
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
        my $next_rec  = {};
        my $next_map  = {};
        my $next_id   = $dbobj->get_column($rel);

        # We have to use the related primary key to safely retrieve
        # the object.
        if ( defined $next_id ) {
            $next_rec->{ $rel } = $next_id;
        }

        # This part is needed to distinguish what to do for more
        # deeply-nested mv_maps. In such cases only the related
        # primary id ($next_id) is used to retrieve the object; to
        # edit the bridging object it must be linked to a view_key via
        # an indeterminate number of hashrefs.
        if ( ref $next_attr eq 'HASH' ) {
            $next_map = $next_attr;
        }
        else {
            $next_rec->{ $next_attr } = $rec->{ $view_key };
        }
        
        # Database updates are not done below here, for the sake of
        # interface consistency.
        my $value = $self->_build_db_obj( $next_rec, $c, $next_rs, $next_map, 1 );
        my @pks = $next_rs->result_source()->primary_columns();
        if ( scalar @pks != 1 ) {
            confess("Error: Unable to update relationship with table not having only one primary column.");
        }
        my $pk = $pks[0];
        $dbobj->set_column( $rel, $value->$pk );
    }

    unless ( $no_update ) {
        eval {
            $dbobj->update_or_insert();
        };
        if ($@) {
            $c->response->status('403');  # Forbidden
            
            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to save one or more objects to database: $@";
        }
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
