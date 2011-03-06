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
# $Id$

use strict;
use warnings;

package BeerFestDB::Loader::RowIterator;

use Moose;
use Carp;
use Text::CSV_XS;

has 'file'        => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1 );

has 'csv_parser'  => ( is    => 'rw',
                       isa   => 'Text::CSV_XS' );

has 'header'      => ( is     => 'rw',
                       isa    => 'ArrayRef[Str]' );

has '_filehandle' => ( is       => 'rw',
                       isa      => 'Filehandle' );

sub BUILD {

    my ( $self, $params ) = @_;

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
	    allow_loose_quotes => 1,
        }
    );

    $self->csv_parser( $csv_parser );

    open( my $fh, '<', $self->file() )
        or die("Unable to open input file: $!\n");
    $self->_filehandle( $fh );

    # Scan through the file to the first non-commented line.
    my $header = $csv_parser->getline( $fh );
    HEADERLINE:
    while( join( q{}, @$header ) =~ /\A \s* #/xms ) {
        $header = $csv_parser->getline( $fh );
        last HEADERLINE unless $header;
    }

    unless( $header ) {
        croak("Unable to detect a suitable header line in file.\n");
    }

    # Strip whitespace.
    $header = [ map { $_ =~ s/\A \s* (.*?) \s* \z/$1/xms; $_ } @$header ];

    # Check for duplicated headings.
    my %count;
    foreach my $col ( @$header ) {
        $count{ $col }++;
    }
    if ( grep { $_ > 1 } values %count ) {
        croak("Header contains duplicated column names.\n");
    }
    
    $self->header( $header );

    return;
}

sub next {

    my ( $self ) = @_;

    my $csv = $self->csv_parser();
    my $fh  = $self->_filehandle();

    my $line = $csv->getline( $fh );

    BODYLINE:
    while( join( q{}, @$line ) =~ /\A \s* #/xms ) {
        $line = $csv->getline( $fh );
        last BODYLINE unless $line;
    }

    unless ( $line ) {

        # Check that parsing completed successfully.
        my ( $error, $mess ) = $csv->error_diag();
        if ( $error != 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
            die(
                sprintf(
                    "Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
                    $mess,
                    $csv->error_input(),
                ),
            );
        }
        else {
            return;  # EOF
        }
    }

    my %data;
    @data{ @{ $self->header() } } = @$line;

    return \%data;
}


package BeerFestDB::Loader;

use Moose;

use Readonly;
use Carp;

use BeerFestDB::ORM;

has 'database' => ( is       => 'ro',
                    isa      => 'DBIx::Class::Schema',
                    required => 1 );

sub load {

    my ( $self, $file ) = @_;

    my $iter = BeerFestDB::Loader::RowIterator->new( file => $file );

    while ( my $row = $iter->next() ) {
        $self->_load_data( $row );
    }

    return;
}

{ # BEGIN LOAD_DATA SCOPE

my ( %KeyUsed, %ObjCache, %ClassUsed );

sub _load_data {

    my ( $self, $row ) = @_;

    # We need a loop at the per-row level: while any unused keys
    # are left, repeat _load_row_data.
    %KeyUsed = map { $_ => 0 } keys %$row;
    while ( any { $_ == 0 } values %KeyUsed ) {
        $self->_load_row_data( $row );
    }
}

sub _list_unused {
    
    my ( $self ) = @_;
    
    my %check  = grep { $KeyUsed{$_} == 0 } keys %KeyUsed;
    my @unused = sort keys %check;

    return \@unused;
}

sub _load_row_data {  # Recursive method.

    my ( $self, $row, $class ) = @_;

    my ( $rs, $obj );

    DATAKEY:
    while ( ! defined $class ) {

        # Find first unused key, select that as the class.
        my $unused = $self->_list_unused();
            
        # If no unused keys left, return.
        last DATAKEY if ( scalar @{ $unused } == 0 );

        # Arbitrarily choose a column key.
        my $next = $unused->[0];

        # Make sure the class exists in the database; if not, try
        # the next key, raise a warning and set the key to
        # used.
        my ( $cand, $attr ) = $self->_split_colname( $next );
        $rs = $self->database->resultset($cand);

        unless ( defined $cand && defined $attr && defined $rs ) {

            # FIXME might want to limit warnings to once per run, not once per row.
            warn(qq{Warning: unrecognised column name "$next"\n});
            $KeyUsed{ $next }++;
            next DATAKEY;
        }
    }

    return unless defined $class;

    # Simple check for cycles in recursion. This really shouldn't happen.
    if ( $ClassUsed{ $class }++ ) {
        die("Error: cyclic dependency detected in the database schema.\n");
    }

    # Pull out all the keys relating to $class.
    my ( %obj_attr, @keys_used );
    COLUMN:
    foreach my $key ( @{ $self->_list_unused() } ) {
        my ( $key_class, $key_attr ) = $self->_split_colname( $key );
        
        unless ( defined $key_class && defined $key_attr ) {

            # FIXME might want to limit warnings to once per run, not once per row.
            warn(qq{Warning: unrecognised column name "$key"\n});
            $KeyUsed{ $key }++;
            next COLUMN;
        }
        
        next COLUMN unless $key_class eq $class;

        # Check that $key_attr is a valid $key_class attr FIXME
        unless ( $rs->result_source->has_column( $key_attr ) ) {
            croak(qq{Error: Database class "$class" has no column named "$key_attr".\n});
        }

        $obj_attr{ $key_attr } = $row->{ $key_attr };
        $KeyUsed{ $key }++;
    }

    # If any of the object database attributes correspond to
    # unused keys, check if the keys have been used. If so, pull
    # out the object from the cache (keyed by target class) and
    # dump them in %obj_hash; otherwise, recurse down a level and
    # create those objects.
    foreach my $relname ( $rs->result_source()->relationships() ) {
        my $target_class = $rs->result_source()->related_class( $relname );
        my $target;
        unless ( my $target = $ObjCache{$target_class} ) {

            # check unused row keys for $target_class
            foreach my $key ( @{ $self->_list_unused() } ) {
                my ( $key_class, $key_attr ) = $self->_split_colname( $key );
                if ( $key_class eq $target_class ) {

                    # Recurse here.
                    $target = $self->_load_row_data( $row, $target_class );
                }
            }
        }
        $obj_attr{ $relname } = $target if defined $target;
    }

    # See if all the required attributes for this $class are
    # present.
    my ( $req, $opt ) = $self->_find_required_cols( $class );
    unless ( $self->_confirm_required_cols( \%obj_attr, $req ) ) {
        croak(qq{Error: Missing required attributes for class "$class": }
                  . join(", ", @$req) . "\n");
    }

    # Actually create the object belonging to $class FIXME. Also
    # put it into %ObjCache.
    $obj = $rs->find_or_create( \%obj_attr );
    $ObjCache{ $class } = $obj;

    return $obj;
}

} # END LOAD_DATA SCOPE

sub _split_colname {

    my ( $self, $colname ) = @_;

    my @parts = split /[.-|: ]+/, $colname, 2;

    return @parts;
}

sub _check_not_null {

    my ( $self, $value ) = @_;

    return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
}

sub _find_required_cols {

    my ( $self, $resultset ) = @_;

    my $source = $resultset->result_source();

    my %is_pk = map { $_ => 1 } $source->primary_columns();

    my @cols = $source->columns();

    my ( @required, @optional );
    foreach my $col (@cols) {

	# FIXME we should introspect to identify primary
	# key/autoincrement columns where possible.
	next if $is_pk{ $col };
	my $info = $source->column_info($col);
	if ( $info->{'is_nullable'} ) {
	    push ( @optional, $col );
	}
	else {
	    push ( @required, $col );
	}
    }

    return ( \@required, \@optional );
}

sub _confirm_required_cols {

    my ( $self, $args, $required ) = @_;

    my $problem;
    foreach my $col ( @{ $required } ) {
	unless ( $self->_check_not_null( $args->{$col} ) ) {
	    warn(qq{Warning: Required column value "$col" not present.\n});
	    $problem++;
	}
    }

    if ( $problem ) {
	return;
    }
    else {
	return 1;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

1;

