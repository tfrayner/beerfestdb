package BeerFestDB::Web::Controller::Currency;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Currency - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Currency' );

    # Maps View onto Model columns.
    my %mv_map = (
        currency_id     => 'currency_id',
        currency_code   => 'currency_code',
        currency_number => 'currency_number',
        currency_format => 'currency_format',
        exponent        => 'exponent',
        currency_symbol => 'currency_symbol',
    );

    my @currencies;
    while ( my $obj = $rs->next() ) {
        my %curr_info = map { $_ => $obj->get_column($mv_map{$_}) } keys %mv_map;
        push @currencies, \%curr_info;
    }

    $c->stash->{ 'objects' } = \@currencies;
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
