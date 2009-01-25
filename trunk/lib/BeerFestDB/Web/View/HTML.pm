package BeerFestDB::Web::View::HTML;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        BeerFestDB::Web->path_to( 'root', 'src' ),
        BeerFestDB::Web->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
});

=head1 NAME

BeerFestDB::Web::View::HTML - Catalyst TTSite View

=head1 SYNOPSIS

See L<BeerFestDB::Web>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Tim Rayner

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

