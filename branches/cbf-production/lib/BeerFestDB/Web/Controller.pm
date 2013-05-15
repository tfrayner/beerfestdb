#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

package BeerFestDB::Web::Controller;
use Moose;
use namespace::autoclean;

use List::Util qw(first);
use Carp;
use utf8;
use Encode;

BEGIN {extends 'Catalyst::Controller'; }

with 'BeerFestDB::DBHashRefValidator';

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

sub raise_exception : Private {

    my ( $self, $c, $message ) = @_;

    $c->error($message);

    die($message);
}

sub generate_json_and_detach : Private {

    my ( $self, $c, $rs ) = @_;

    my @objects;
    while ( my $obj = $rs->next ) {
        push @objects, $self->generate_object_viewhash($obj);
    }

    $c->stash->{ 'success' } = JSON::Any->true();
    $c->stash->{ 'objects' } = \@objects;
    $c->detach( $c->view( 'JSON' ) );
}

sub generate_object_viewhash : Private {

    my ( $self, $obj ) = @_;

    # Maps View onto Model columns.
    my %mv_map = %{ $self->model_view_map() };

    my %obj_info;
    foreach my $key ( keys %mv_map ) {
        my $value = $self->viewhash_from_model($key, $obj);
        if ( defined $value ) {
            $obj_info{ $key } = $value;
        }
    }

    return \%obj_info;
}

=head2 form_json_and_detach

=cut

sub form_json_and_detach : Private {

    my ( $self, $c, $rs, $pk ) = @_;

    my $id = $c->request->param( $pk );

    if ( defined $id ) {
        my $obj = $rs->find({ $pk => $id });

        if ( $obj ) {
            $c->stash->{ 'data' } = $self->generate_object_viewhash( $obj );
            $c->stash->{ 'success' } = JSON::Any->true();
        }
        else {
            $c->stash->{ 'success' } = JSON::Any->false();
            $c->stash->{ 'error' } = qq{Error: Unable to find $pk "$id".};
        }
    }
    else {
        $c->stash->{ 'success' } = JSON::Any->false();
        $c->stash->{ 'error' } = "Error: $pk is not defined.";
    }

    $c->detach( $c->view( 'JSON' ) );

    return;
}

sub viewhash_from_model : Private {

    # Method using a JSON view object attribute name (from
    # model_view_map), to retrieve the appropriate model attribute
    # from a DBIx::Class::Row object.
    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    unless ( defined $dbrow ) {
        return;
    }

    $lookup ||= $self->model_view_map()->{ $view_key } || $view_key;

    if ( ref $lookup eq 'HASH' ) {

        # Hashrefs should contain relationship => column style
        # structures (this is recursive).
        my @children;
        foreach my $relation ( keys %$lookup ) {
            push @children,
                $self->viewhash_from_model( $lookup->{$relation},
                                            $dbrow->$relation,
                                            $lookup->{$relation} );
        }

        if ( scalar @children > 1 ) {
            confess("Error: Multiple keys in model_view_map"
                        . " relationships are not supported.");
        }
        elsif ( scalar @children < 1 ) {
            return;
        }
        return $children[0];
    }
    else {
        return $dbrow->get_column( $lookup );
    }
}

sub _get_product_category : Private {

    my ( $self, $c, $dbobj, $null_okay ) = @_;

    # Sometimes we will be passed a null object during subsequent
    # recursion; e.g. into orphaned CaskManagement objects.
    if ( ! $dbobj ) {
        return if $null_okay; # Only CaskManagement for the moment.
        $self->raise_exception($c, "Unable to track object back to product_category.\n");
    }

    my $result_source = $dbobj->result_source();
    my $rs            = $result_source->resultset();
    my $classname     = $result_source->source_name();

    # FIXME note that this may be rather too heavy on DB queries,
    # especially for large lists of updates.
    my %catmap = (
        'Product'         => sub { $_[0]->product_category_id() },
        'FestivalProduct' => sub { $self->_get_product_category( $c, $_[0]->product_id ) },
        'Gyle'            => sub { $self->_get_product_category( $c, $_[0]->festival_product_id ) },
        'Cask'            => sub { $self->_get_product_category( $c, $_[0]->gyle_id ) },
        'CaskMeasurement' => sub { $self->_get_product_category( $c, $_[0]->cask_id ) },
        'ProductOrder'    => sub { $self->_get_product_category( $c, $_[0]->product_id ) },
        'CaskManagement'  => sub { $self->_get_product_category( $c, $_[0]->casks->first() ||
                                                                     $_[0]->product_order_id, 1 ) },
    );

    if ( my $fun = $catmap{ $classname } ) {
        return $fun->($dbobj);
    }
    else {
        $self->raise_exception($c, qq{Product category retrieval mapping not implemented for "$classname" objects.\n});
    }
}

sub _confirm_category_authorisation : Private {

    my ($self, $c, $dbobj) = @_;

    if ( ! $c->user ) {
        $self->raise_exception($c, "Error: user not logged in. How could this happen?!\n");
    }

    # Admin users get all the privs.
    return if $c->check_any_user_role('admin');

    my $classname = $dbobj->result_source()->source_name();

    # Make sure this list matches the keys of %catmap, above.
    if ( first { $_ eq $classname } qw( Product FestivalProduct Gyle
                                        Cask ProductOrder CaskManagement
                                        CaskMeasurement  ) ) {

        my $pcat    = $self->_get_product_category($c, $dbobj);

        # Creation of new CaskManagements has to occur in the absence
        # of any link to product_category.
        return if ( ! defined $pcat && $classname eq 'CaskManagement' );

        my $pcat_id = $pcat->get_column('product_category_id');

        # Test that pcat is in $c->user's roles->categories.
        my $found = $c->user->search_related('user_roles')
                            ->search_related('role_id')
                            ->search_related('category_auths',
                                             { product_category_id => $pcat_id })
                            ->count();

        if ( ! $found ) {
            $self->raise_exception($c,
                                   sprintf(qq{You do not have authorisation to}
                                         . qq{ make changes to the "%s" category.\n},
                                           $pcat->description))
        }
    }
    else {

        # If it's anything else, the user needs to be an admin.
        if ( ! $c->check_any_user_role('manager') ) {
            $self->raise_exception($c,
                                   "Attempting to edit an object which requires"
                                   . " manager or admin privileges\n");
        }
    }
}

sub _add_object_column_attributes : Private {

    my ( $self, $dbobj, $rec, $primary_cols, $mv_map ) = @_;

    my @hashrefs;
    
    VIEW_KEY:
    foreach my $view_key (keys %$rec) {

        # Skip primary columns; we've already dealt with them.
        next VIEW_KEY if ( first { $view_key eq $_ } @$primary_cols );

        # There's a strong risk of key collision from an upper
        # recursion into this one here; to fix this, we have to manage
        # the $mv_map hashref as part of that recursion.
        my $lookup ||= $mv_map->{ $view_key } || $view_key;
        
        if ( ref $lookup eq 'HASH' ) {
            push @hashrefs, $view_key;
        }
        else {
            my $dbval = $rec->{ $view_key };

            # For some reason these don't want to autoconvert, so we
            # do this manually.
            if ( UNIVERSAL::isa($dbval, 'JSON::PP::Boolean') ) {
                $dbval = $dbval ? 1 : 0;
            }

	    # Don't try and save empty strings as integers - strict
	    # MySQL mode complains.
	    my $dt = $dbobj->result_source()
		           ->column_info( $lookup )
			   ->{data_type};
	    if ( defined $dbval && $dbval eq q{} ) {
                if ( $dt eq 'tinyint' ) {
                    $dbval = 0;
                }
                elsif ( $dt eq 'integer' || $dt eq 'decimal' ) {  # int so we can delete cask.stillage_bay
                    $dbval = undef;
                }
            }
            
            $dbobj->set_column( $lookup, $dbval );
        }
    }

    return \@hashrefs;
}

sub _add_object_relationships : Private {

    my ( $self, $c, $rs, $dbobj, $rec, $hashrefs, $mv_map ) = @_;
    
    foreach my $view_key (@$hashrefs) {

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
        # interface consistency. (FIXME we're currently reviewing
        # this, hence 0 on next line; it may be that we need recursive
        # updates for e.g. cask->cask_management and the interface is
        # better controlled by using read-only fields).
        my $value = $self->build_database_object( $next_rec, $c, $next_rs, $next_map, 0 );
        my @pks = $next_rs->result_source()->primary_columns();
        if ( scalar @pks != 1 ) {
            confess("Error: Unable to update relationship with table not having only one primary column.");
        }
        my $pk = $pks[0];
        $dbobj->set_column( $rel, $value->$pk );
    }

    return;
}

sub build_database_object : Private {

    my ( $self, $rec, $c, $rs, $mv_map, $no_update ) = @_;

    foreach my $key ( keys %$rec ) {
        delete $rec->{$key}
            unless $self->value_is_acceptable( $rec->{$key} );
    }

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

    # Secondly, deal with simple table-based attributes.
    my $hashrefs = $self->_add_object_column_attributes($dbobj, $rec, \@primary_cols, $mv_map);

    # Thirdly, we handle the relationships.
    $self->_add_object_relationships($c, $rs, $dbobj, $rec, $hashrefs, $mv_map);

    # Note that this will raise an exception to derail the enclosing
    # transaction if the user is not authorised to make changes.
    $self->_confirm_category_authorisation($c, $dbobj) if $dbobj->is_changed();

    unless ( $no_update ) {
        eval {
            $dbobj->update_or_insert();
        };
        if ($@) {

	    $c->log->error("DB transaction failure: $@");

	    my @missing = $self->resultset_missing_requirements( $rec, $rs );

	    my $message;
	    if ( scalar @missing ) {
	        my @bad = map { s/_id\z//xms; s/_+/ /g; $_ } @missing;
	        $message = sprintf("Unable to save %s object (missing values for ",
				   $rs->result_source->source_name())
		  . join(", ", @bad) . ").";
	    }
	    else {

		my $valstr = join(', ', map { $_ . ' => ' . $rec->{$_} } keys %$rec);
		$message = sprintf("Unable to save %s object with values: %s",
				   $rs->result_source->source_name(), $valstr);
	    }
         
  	    # Called within a transaction, we die hard.
	    $self->raise_exception( $c, $message . "\n" );
        }
    }

    return( $dbobj );
}

sub value_is_acceptable : Private {  # Required by DBHashRefValidator

    my ( $self, $value ) = @_;

    return 1;  # Undef values must be allowed if we want to break relationships.
}

sub decode_json_changes : Private {

    my ( $self, $c ) = @_;
 
    my $j = JSON::XS->new->utf8;
    my $data;
    eval { $data = $j->decode( encode('UTF-8', $c->request->param( 'changes' ) ) ) };
    if ($@) {
	$c->error("Unable to parse submitted JSON upload: $@");
	$self->detach_with_txn_failure( $c );
    }

    return $data;
}

=head2 write_to_resultset

Passed a resultset and a context object, map the changes in the
context back to the database column names, and attempt to write it to
the database.

=cut

sub write_to_resultset : Private {

    my ( $self, $c, $rs ) = @_;

    my $data = $self->decode_json_changes( $c );

    # Wrap everything in a transaction - all should pass, or none.
    eval {
        $rs->result_source()->schema()->txn_do(
            sub {
                foreach my $rec ( @{ $data } ) {
                    my $dbobj = $self->build_database_object( $rec, $c, $rs );
                }
            }
        );
    };
    if ( $@ or scalar @{ $c->error } ) {
        $self->detach_with_txn_failure( $c );
    };

    $c->stash->{ 'success' } = JSON::Any->true();
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 delete_from_resultset

Passed a resultset and a context object, delete the appropriate
objects from the database.

=cut

sub delete_from_resultset : Private {

    my ( $self, $c, $rs ) = @_;

    my $data = $self->decode_json_changes( $c );

    eval {
        $rs->result_source()->schema()->txn_do(
            sub {
                foreach my $id ( @{ $data } ) {
                    my $rec = $rs->find($id);
                    eval {
                        $rec->delete() if $rec;
                    };
                    if ($@) {
                        $self->raise_exception($c, sprintf("Unable to delete %s object with ID=%s\n",
                                                           $rs->result_source->source_name(), $id));
                    }
                }
            }
        );
    };
    if ( $@ or scalar @{ $c->error } ) {
        $self->detach_with_txn_failure( $c );
    };

    $c->stash->{ 'success' } = JSON::Any->false();
    $c->detach( $c->view( 'JSON' ) );
}

sub detach_with_txn_failure : Private {

    my ( $self, $c, $error ) = @_;

    $error ||= join("; ", @{ $c->error });

    $c->clear_errors();

    $error =~ s/\A (.*) [\r\n]* \z/$1/xms;

    $error = "Database not changed: $error";
    $c->log->error($error);
    $c->response->status('403');  # Forbidden; must use this or
                                  # similar for ExtJS to detect
                                  # failure.
    $c->stash->{ 'success' } = JSON::Any->false();
    $c->stash->{ 'error' }   = $error;
    $c->detach( $c->view( 'JSON' ) );    
}

=head2 get_default_currency

=cut

sub get_default_currency : Private {

    my ( $self, $c ) = @_;

    my $def = $c->model('DB::Currency')->find({
        currency_code => $c->config->{'default_currency'},
    }) or $self->raise_exception($c, "Error retrieving default currency; check config settings.\n");

    $c->stash->{ 'default_currency' } = $def->currency_id();

    return;
}

=head2 get_default_sale_volume

=cut

sub get_default_sale_volume : Private {

    my ( $self, $c ) = @_;

    my $def = $c->model('DB::SaleVolume')->find({
        description => $c->config->{'default_sale_volume'},
    }) or $self->raise_exception($c, "Error retrieving default sale volume; check config settings.\n");

    $c->stash->{ 'default_sale_volume' } = $def->sale_volume_id();

    return;
}

=head2 get_default_product_category

=cut

sub get_default_product_category : Private {

    my ( $self, $c ) = @_;

    my $def = $c->model('DB::ProductCategory')->find({
        description => $c->config->{'default_product_category'},
    }) or $self->raise_exception($c, "Error retrieving default product_category; check config settings.\n");

    $c->stash->{ 'default_product_category' } = $def->product_category_id();

    return;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
