#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2013 Tim F. Rayner
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

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;

use BeerFestDB::ORM;
use BeerFestDB::Web;

package Preloader;

use Moose;

has 'database'  => ( is       => 'rw',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

with 'BeerFestDB::MenuSelector';
with 'BeerFestDB::CaskPreloader';

sub preload_festival {

    my ( $self ) = @_;

    my $db = $self->database();

    my @batches = $self->festival->search_related('order_batches')->all();

    foreach my $batch ( @batches ) {
        $self->_preload_order_batch($batch)
    }

    return;
}

sub _preload_order_batch {

    my ( $self, $batch ) = @_;

    foreach my $order ( $batch->search_related('product_orders')->all() ) {
        $self->preload_product_order($order)
    }

    return;
}

package main;

sub parse_args {

    # FIXME this may actually be superfluous.

    my ( $want_help );

    GetOptions(
        "h|help"     => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    return( );
}

# All settings currently taken from the main BeerFestDB::Web config file.
my $config = BeerFestDB::Web->config();
my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );
my $loader = Preloader->new(database => $schema);
$loader->preload_festival();


__END__

=head1 NAME

preload_festival_casks.pl

=head1 SYNOPSIS

 preload_festival_casks.pl

=head1 DESCRIPTION

Stub documentation for preload_festival_casks.pl, 
created by template.el.

It looks like the author of this script was negligent 
enough to leave the stub unedited.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Tim F. Rayner

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

Probably.

=cut
