package BeerFestDB::Web::Controller::CompanyRegion;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::CompanyRegion - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::CompanyRegion' );

    # Maps View onto Model columns.
    my %mv_map = (        
        company_region_id  => 'company_region_id',
        description        => 'name',
    );

    my @regions;
    while ( my $obj = $rs->next() ) {
        my %region_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @regions, \%region_info;
    }

    $c->stash->{ 'objects' } = \@regions;
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
