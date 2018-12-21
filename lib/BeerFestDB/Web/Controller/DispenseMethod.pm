#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2017 Tim F. Rayner
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

package BeerFestDB::Web::Controller::DispenseMethod;
use Moose;
use namespace::autoclean;

BEGIN { extends 'BeerFestDB::Web::GenericGrid'; }

=head1 NAME

BeerFestDB::Web::Controller::DispenseMethod - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        dispense_method_id   => 'dispense_method_id',
        description          => 'description',
    });

    $self->model_name('DB::DispenseMethod');
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
