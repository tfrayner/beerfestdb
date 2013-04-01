#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2012-2013 Tim F. Rayner
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
# $Id: upload_beerlist.pl 381 2012-05-17 14:35:44Z tfrayner $

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::YAML;
use Text::CSV_XS;
use List::Util qw(first);
use Scalar::Util qw(looks_like_number);
use BeerFestDB::ORM;

package CaskUpdater;

use Moose;

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

has 'allow_stillage_move' => ( is       => 'ro',
                               isa      => 'Bool',
                               default  => 0,
                               required => 1 );

has '_errors'   => ( is       => 'ro',
                     isa      => 'ArrayRef',
                     required => 1,
                     default  => sub { [] } );

with 'BeerFestDB::MenuSelector';

sub assign_cellar_number {

    my ( $self, $cask, $id ) = @_;

    if ( defined $id ) {
        if ( ! looks_like_number( $id ) ) {
            die("Error: This cask_cellar_id doesn't look like a number: $id\n");
        }
        
        # Remove the cellar number from the cask that
        # currently has it.
        my $altcask = $self->database->resultset('Cask')
                           ->find({ festival_id => $self->festival->id(),
                                    gyle_id     => $cask->get_column('gyle_id'),
                                    internal_reference => $id });
        if ( $altcask && $altcask->cellar_reference != $cask->cellar_reference ) {
            $altcask->set_column('internal_reference', undef);
            $altcask->update();
        }
        
        $cask->set_column('internal_reference', $id);
    }

    return;
}

sub assign_stillage_location {

    my ( $self, $cask, $loc ) = @_;

    my $stillage = $self->database->resultset('StillageLocation')
                                  ->find({ festival_id => $self->festival->id(),
                                           description => $loc })
                                      or die(qq{Error: Stillage location "$loc" }.
                                                 qq{not found.\n});
    my $caskloc = $cask->get_column('stillage_location_id');
    if ( ! defined $caskloc || $caskloc != $stillage->stillage_location_id ) {
        if ( $self->allow_stillage_move ) { # Initial stillage assignment only.
            $cask->set_column('stillage_location_id',
                              $stillage->stillage_location_id());
        }
        else {
            push @{ $self->_errors },
                sprintf("Error: Attempting to move cask %s between stillages.",
                        $cask->cellar_reference);
        }
    }

    return;
}

sub update_cask {

    my ( $self, $cask, $row ) = @_;

    # First deal with stillage location. This is required
    # to prevent one well-meaning cellar person from
    # inadvertently screwing with another stillage's info.
    my $loc = $row->{ 'stillage_location' };
    if ( ! defined $loc ) {
        die("Error: stillage_location not defined.");
    }
    $self->assign_stillage_location( $cask, $loc );
    
    # Cellar id ("internal_reference").
    if ( my $id = $row->{ 'cask_cellar_id' } ) {
        $self->assign_cellar_number($cask, $id);
    }
    
    # Stillage bay.
    if ( my $bay = $row->{ 'stillage_bay' } ) {
        if ( defined $bay ) {
            if ( ! looks_like_number( $bay ) ) {
                die("Error: This stillage_bay doesn't look like a number: $bay\n");
            }
            $cask->set_column('stillage_bay', $bay);
        }
    }

    # Bay position.
    if ( my $baypos = $row->{ 'bay_position' } ) {
        my $pos = $self->database->resultset('BayPosition')
            ->find({ description => $baypos })
                or die(qq{Error: Bay position "$baypos" not found.});
        $cask->set_column('bay_position_id',
                          $pos->bay_position_id());
    }
    
    $cask->update();

    return;
}

sub load {

    my ( $self, $datafile ) = @_;

    my $csv_parser = Text::CSV_XS->new(
        {   sep_char    => qq{\t},
            quote_char  => qq{"},                   # default
            escape_char => qq{"},                   # default
            binary      => 1,
            allow_loose_quotes => 1,
        }
    );

    open(my $fh, '<', $datafile)
        or die(qq{Error: unable to open input file "$datafile".\n});

    # Find header line.
    my @header;
    HEADER:
    while ( scalar @header == 0 ) {
        my $line = $csv_parser->getline($fh);
        my $lstr = join('', @$line);
        next HEADER if $lstr =~ /^\s*#/;  # skip comments
        next HEADER if $lstr =~ /^\s*$/;  # skip blank lines
        @header = @$line;
    }

    if ( scalar @header == 0 ) {
        die("Unable to find a suitable header line in the input file.");
    }

    ## Die on unrecognised columns.
    foreach my $col ( @header ) {
        unless ( first { $col eq $_ } qw(cask_festival_id cask_cellar_id
                                         stillage_location stillage_bay
                                         bay_position) ) {
            die("Unrecognised column heading: $col\n");
        }
    }

    ## Run the entire load in a single transaction.
    eval {
        $self->database->txn_do(
            sub {
                
                CASK:
                while ( my $line = $csv_parser->getline($fh) ) {
                    my $lstr = join('', @$line);
                    next CASK if $lstr =~ /^\s*#/;  # skip comments
                    
                    my %row;
                    @row{ @header } = @$line;
                    
                    my $cfid = $row{ 'cask_festival_id' };
                    unless ( defined $cfid ) {
                        warn("Row does not contain cask_festival_id. Skipping.\n");
                        next CASK;
                    }
                    
                    my $cask = $self->database->resultset('Cask')
                        ->find({ festival_id      => $self->festival->id(),
                                 cellar_reference => $cfid })
                            or die(qq{Error: Cask with cellar_reference "$cfid" }
                                       . qq{not found.\n});

                    $self->update_cask( $cask, \%row );
                }
                
                # Useful for reporting discrepancies back to cellar managers.
                my $errors = $self->_errors();
                if ( scalar @{ $errors } ) {
                    die("The following errors were encountered:\n"
                            . join("\n", @$errors) );
                }
            }
        );
    };
    if ( $@ ) {
        die(qq{Errors encountered during load:\n\n$@});
    }
    else {
        
        # Check that parsing completed successfully.
        my ( $error, $mess ) = $csv_parser->error_diag();
        unless ( $error == 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
            die(sprintf(
		"Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
		$mess,
		$csv_parser->error_input()));
        }
        
        print("Cask information successfully loaded.\n");
    }

    return;
}

package main;

sub parse_args {

    my ( $conffile, $datafile, $allow_stillage_move, $want_help );

    GetOptions(
        "c|config=s"   => \$conffile,
	"f|file=s"     => \$datafile,
	"a|allow"      => \$allow_stillage_move,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $conffile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = Config::YAML->new( config => $conffile );

    return( $config, $datafile, $allow_stillage_move );
}

my ( $config, $datafile, $allow_stillage_move ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $updater = CaskUpdater->new( database            => $schema,
                                allow_stillage_move => $allow_stillage_move );

$updater->load( $datafile );

__END__

=head1 NAME

update_cask_details.pl

=head1 SYNOPSIS

 update_cask_details.pl -c beerfest_web.yml -f tab_delimited_file.csv

=head1 DESCRIPTION

Local CBF-specific script used to update cask cellar ID, stillage
location, bay number and position once stillaging is complete.

=head1 OPTIONS

=head2 -c

The path to the main BeerFestDB config file.

=head2 -a

A flag indicating whether or not to allow casks to be automatically
moved between stillages (default: no).

=head2 -f

The file containing cask details. This should be in tab-delimited format and contain the following headings:

=over 2

=item cask_festival_id

The unique identifier for the cask within the festival.

=item cask_cellar_id

The cask cellar number; i.e. the number of the cask within the gyle,
typically in order of sale. If you have six casks of a given beer,
they will typically be numbered 1 to 6.

=item stillage_location

The name of the stillage upon which the cask rests. These locations
must already have been registered in the database.

=item stillage_bay

The number of the bay on the stillage. Currently only constrained to
being an integer.

=item bay_position

The position of the cask within the bay. This must conform to the
standard list registered in the bay_position table (e.g. "Top Front",
"Bottom Back").

=back

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

