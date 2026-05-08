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
#
# $Id$

package BeerFestDB::Exceptions;

=head1 NAME

BeerFestDB::Exceptions - Exception classes for BeerFestDB

=head1 DESCRIPTION

This module defines exception classes used in BeerFestDB.

=head1 EXPORTS

=head2 UriAuthorizationError

Exception class for handling URI authorization errors.

=cut

use Exception::Class (
    'BeerFestDB::Exceptions::UriAuthorizationError' => {
        fields => ['uri', 'message'],
    },
);
use constant UriAuthorizationError => 'BeerFestDB::Exceptions::UriAuthorizationError';

use Exporter qw/import/;
our @EXPORT_OK = qw(UriAuthorizationError);

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
