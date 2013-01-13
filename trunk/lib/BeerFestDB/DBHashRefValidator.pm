#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010 Tim F. Rayner
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
# $Id: Controller.pm 233 2011-05-15 15:56:58Z tfrayner $

package BeerFestDB::DBHashRefValidator;
use Moose::Role;
use namespace::autoclean;

requires qw(value_is_acceptable);

=head1 NAME

BeerFestDB::DBHashRefValidator - Validation of DB load data.

=head1 DESCRIPTION

Role class for validating hashrefs against the attributes of a
DBIx::Class::ResultSet prior to DB loading.

=head1 METHODS

=cut

sub validate_against_resultset {

    my ( $self, $attrs, $resultset ) = @_;

    my $class = $resultset->result_source()->source_name();

    my ( $required, $optional ) = $self->resultset_required_columns( $resultset );

    my @pk = $resultset->result_source()->primary_columns();
    my %recognised = map { $_ => 1 } @{ $required }, @{ $optional }, @pk;
    foreach my $key ( keys %{ $attrs } ) {
	unless ( $recognised{ $key } ) {
	    die(qq{Unrecognised attribute "$key" for class "$class".}); 
	}
    }
    my @cols =
	$self->resultset_missing_requirements( $attrs, $resultset, $required );

    if ( scalar @cols > 0 ) {
	die(qq{The following required attributes are}
	  . qq{ missing for object of class "$class": }
	      . join(", ", @cols) . "\n");
    }

    return 1;
}

sub resultset_required_columns {

    my ( $self, $resultset ) = @_;

    my $source = $resultset->result_source();

    return $self->resultsource_required_columns($source);
}

sub resultsource_required_columns {

    my ( $self, $source ) = @_;

    my %is_pk = map { $_ => 1 } $source->primary_columns();

    my @cols = $source->columns();

    my ( @required, @optional );
    foreach my $col (@cols) {

	# FIXME we should introspect to identify autoincrement columns
	# where possible.
	next if $is_pk{ $col };
	my $info = $source->column_info($col);
	if ( $info->{'is_nullable'} ) {
	    push ( @optional, $col );
	}
	else {
	    push ( @required, $col );
	}
    }

    return wantarray ? ( \@required, \@optional ) : \@required;
}

sub resultset_missing_requirements {

    my ( $self, $attrs, $resultset, $required ) = @_;

    unless ( $required) {
	$required = $self->resultset_required_columns( $resultset );
    }

    my @problems;
    foreach my $col ( @{ $required } ) {
	unless ( $self->value_is_acceptable( $attrs->{$col} ) ) {
	    push @problems, $col;
	}
    }

    return @problems;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;
