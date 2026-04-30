#
# This file is part of BeerFestDB, a beer festival product management
# system.
#
# Copyright (C) 2026 Tim F. Rayner
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

package BeerFestDB::Web::Plugin::ConditionalOIDC;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

BeerFestDB::Web::Plugin::ConditionalOIDC - Catalyst plugin to conditionally
enable OpenID Connect based on key file availability.

=head1 DESCRIPTION

This plugin runs its C<after 'setup'> hook between ConfigLoader (which
merges the external YAML config) and C<Catalyst::Plugin::OpenIDConnect>
(which attempts to load key files). If the configured key files are not
readable it removes the C<issuer> config block, causing the OpenIDConnect
plugin's own setup hook to skip initialisation gracefully rather than
dying with an error.

Load this plugin immediately before C<OpenIDConnect> so that the Moose
C<after> modifier ordering guarantees it executes first:

    __PACKAGE__->setup(qw/+BeerFestDB::Web::Plugin::ConditionalOIDC OpenIDConnect/);

=cut

after 'setup' => sub {
    my ($app) = @_;

    my $config = $app->config->{'Plugin::OpenIDConnect'};
    return unless $config && ref $config eq 'HASH';

    my $issuer_cfg = $config->{issuer};
    return unless $issuer_cfg && ref $issuer_cfg eq 'HASH';

    # Only private_key_file is required by the plugin; public_key_file is
    # optional (the public key can be derived from the private key).
    # Check whichever files are actually configured.
    for my $keyfile ( qw( private_key_file public_key_file ) ) {
        my $path = $issuer_cfg->{$keyfile};
        next unless defined $path;

        unless ( -r $path ) {
            $app->log->warn(
                "OpenID Connect: $keyfile '$path' is not readable. "
              . "OpenID Connect functionality will be disabled."
            );
            # Remove the issuer block so that the OpenIDConnect plugin's
            # own after-setup hook finds no issuer config and skips
            # initialisation rather than dying.
            delete $config->{issuer};
            return;
        }
    }
};

1;

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut
