package BeerFestDB::Web::Controller::Currency;
use Moose;
use namespace::autoclean;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::Currency - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        currency_id     => 'currency_id',
        currency_code   => 'currency_code',
        currency_number => 'currency_number',
        currency_format => 'currency_format',
        exponent        => 'exponent',
        currency_symbol => 'currency_symbol',
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::Currency' );

    $self->generate_json_and_detach( $c, $rs );
}

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
