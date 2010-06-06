package BeerFestDB::Web::Controller::Company;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Company - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched BeerFestDB::Web::Controller::Company in Company.');
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my @db_objs = $c->model( 'DB::Company' )->all();

    my @companies;
    foreach my $obj ( @db_objs ) {
        my %comp = map { $_ => $obj->$_ } qw( company_id
                                              name
                                              loc_desc
                                              year_founded
                                              url
                                              comment );
        if ( my $region = $obj->company_region_id ) {
            $comp{company_region_id} = $region->company_region_id();
        }
        push @companies, \%comp;
    }

    $c->stash->{ 'objects' } = \@companies;
    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 grid

=cut

sub grid : Local {

    my ( $self, $c ) = @_;

    my @regions = $c->model('DB::CompanyRegion')->all();
    $c->stash->{regions} = \@regions;

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Company' );

    my $j = JSON::Any->new;
    my $data = $j->jsonToObj( $c->request->param( 'changes' ) );

    foreach my $rec ( @{ $data } ) {

        eval {
            my $company = $rs->update_or_create( $rec );
        };
        if ($@) {
            $c->response->status('403');  # Forbidden

            # N.B. flash_to_stash doesn't seem to work for JSON views.
            $c->stash->{error} = "Unable to save one or more products to database: $@";
        }
    }

    $c->detach( $c->view( 'JSON' ) );

    return;
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Company' );

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
            $c->stash->{error} = "Unable to delete one or more products: $@";
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
