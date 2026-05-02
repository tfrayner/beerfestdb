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

package BeerFestDB::Role::CsvParser;
use Moose::Role;
use namespace::autoclean;
use Text::CSV_XS;

has 'csv_file' => ( is       => 'ro',
                    isa      => 'Str',
                    required => 1 );

has 'filehandle' => ( is       => 'ro',
                      isa      => 'FileHandle',
                      lazy     => 1,
                      builder  => '_build_filehandle' );

has 'csv_parser' => ( is       => 'ro',
                      isa      => 'Text::CSV_XS',
                      lazy     => 1,
                      builder  => '_build_csv_parser' );

sub _build_filehandle {

    my ( $self ) = @_;

    my $file = $self->csv_file();

    open( my $fh, '<', $file )
        or die(qq{Error: unable to open input file "$file".\n});

    return $fh;
}

sub _build_csv_parser {
    
    my ( $self ) = @_;
    
    # All supported files are tab-delimited, with double-quote as the quote character and
    # escape character, and binary mode enabled to allow for special characters. Loose quotes
    # are allowed to handle cases where the input data may not be perfectly formatted.
    my $_csv_parser //= Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
            allow_loose_quotes => 1,
        }
    );

    return $_csv_parser;
}

=head1 NAME

BeerFestDB::Role::CsvParser - Parsing CSV files for BeerFestDB.

=head1 DESCRIPTION

This is a Role class used to parse CSV files and populate the database with the parsed information.

=head1 METHODS

=head2 getline

This method is provided by the Text::CSV_XS parser object and is used to read lines from the CSV file. It returns
an array reference containing the fields of the current line, or undef if there are no more lines to read. If the
C<$is_header> argument is true, it returns the fields as they are read from the file. If C<$is_header> is false, 
it processes the fields to replace any values that indicate missing data (such as "NA", "N/A", "ND", "N/D", "NULL",
"TBC", "TBD", or blank values) with an empty string. Whitespace around the fields is preserved.

=cut

sub getline {

    my ( $self, $is_header ) = @_;

    my $csv_parser = $self->csv_parser();

    confess "CSV parser not initialized" unless $csv_parser;
    confess "Filehandle not initialized" unless $self->filehandle;

    print "Reading line from CSV file...\n";

    my $fields = $csv_parser->getline( $self->filehandle );

    # If this is not a search for the header line, strip out fields indicating missing values.
    if ( ! ( $is_header || 0 ) ) {
        $fields = [ map { m/\A \s* (NA|N\/A|ND|N\/D|NULL|TBC|TBD|) \s* \z/ixms ? q{} : $_ } @$fields ];
    }

    return $fields;
}

=head2 confirm_eof

This method is used to confirm that the end of the CSV file has been reached after parsing is complete. It 
checks for any parsing errors and dies with an error message if any errors are found, including the bad
input that caused the error. If no errors are found, it returns true.

=cut

sub confirm_eof {

    my ( $self ) = @_;

    my ( $error, $mess ) = $self->csv_parser()->error_diag();

    # Check that parsing completed successfully.
    unless ( $error == 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
        die(sprintf(
                "Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
                $mess,
                $self->csv_parser()->error_input()));
    }

    return (1);
}

=head2 get_headers 

This method is used to find the header line in the CSV file, which contains the column names.
It skips any lines that are blank or start with a "#" character (indicating a comment) until
it finds a suitable header line. It returns an array reference containing the header fields.

=cut

sub get_headers {

    my ( $self ) = @_;

    # Find header line. Skip blank lines and comments (lines starting with "#").
    my @header;
    HEADER:
    while ( scalar @header == 0 ) {
        print "Reading header line...$self\n";
        my $line = $self->getline(1);
        print "Read header line...\n";
        my $lstr = join('', @$line);
        next HEADER if $lstr =~ /^\s*#/;  # skip comments
        next HEADER if $lstr =~ /^\s*$/;  # skip blank lines
        @header = @$line;
    }

    if ( scalar @header == 0 ) {
        die("Unable to find a suitable header line in the input file.");
    }

    # Strip leading and trailing whitespace.
    my @clean_header = map { $_ =~ s/\A \s*(.*?)\s* \z/$1/xms; $_ } @header;

    return \@clean_header;
}

=head2 parse_boolean

This method is used to parse boolean values from the CSV file. It handles various 
representations of true and false values, including blank values and "n/a" values 
as false, and "yes", "true", "1" values as true. If the value cannot be parsed as a 
boolean, it dies with an error message.

=cut

sub parse_boolean {

    my ( $self, $value ) = @_;

    # Handle blank values and "n/a" values as false.
    return undef if !defined($value) || $value eq q{} || $value =~ /\A (\s+|n\/?[ad]) \z/ixms;

    # Handle "no", "false", "0" values as false.
    return 1 if defined($value) && $value =~ /\A (?:y|yes|t|true|1) \z/ixms;

    # Handle "yes", "true", "1" values as true.
    return 0 if defined($value) && $value =~ /\A (?:n|no|f|false|0) \z/ixms;

    die(sprintf("Unable to parse boolean value: %s", defined($value) ? $value : 'undef'));
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

no Moose::Role;

1;
