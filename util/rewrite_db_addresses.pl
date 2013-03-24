#!/usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use BeerFestDB::ORM;
use BeerFestDB::Web;

my $config = BeerFestDB::Web->config();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $rs = $schema->resultset('Contact');

while ( my $contact = $rs->next() ) {

    my $address = $contact->street_address();

    next unless $address;

    $address =~ s/(?<!\d), *(?!\n)/,\n/g;
    $address =~ s/(\bP[. ]*O[.]* +Box +\d+\b), *(?!\n)/$1,\n/g;

    print $address . "\n------------------\n";

    $contact->set_column('street_address', $address);
    $contact->update();
}


__END__

=head1 NAME

rewrite_db_addresses.pl

=head1 SYNOPSIS

 rewrite_db_addresses.pl

=head1 DESCRIPTION

The database stores street addresses as free text. This script simply
attempts to spruce up the formatting of that text so it can be used
directly on orders and envelopes. This will, at least initially, be
pretty brain-dead.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut
