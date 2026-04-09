#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2012-2026 Tim F. Rayner
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
use BeerFestDB::ORM;
use BeerFestDB::Web;

package CaskUpdater;

use Moose;
use List::Util qw(first);
use Scalar::Util qw(looks_like_number);

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

has 'allow_stillage_move' => ( is       => 'ro',
                               isa      => 'Bool',
                               default  => 0,
                               required => 1 );

has 'require_stillage_loc' => ( is       => 'ro',
                                isa      => 'Bool',
                                default  => 1,
                                required => 1 );

has '_errors'   => ( is       => 'ro',
                     isa      => 'ArrayRef',
                     required => 1,
                     default  => sub { [] } );

with 'BeerFestDB::MenuSelector';

with 'BeerFestDB::CsvParser';

with 'BeerFestDB::PriceMunger';

sub BUILD {

    my ( $self, $params ) = @_;

    # Cache the default currency for use by the price parsing and formatting methods (PriceMunger role).
    my $currency = $self->database()->resultset('Currency')->find({
        currency_code => BeerFestDB::Web->config()->{ default_currency }
    }) or die(qq{Error: unable to find default currency in database.\n});

    $self->default_currency($currency);

    return;
}

sub assign_cask_price {

    my ( $self, $caskman, $price ) = @_;

    if ( defined $price ) {
        if ( ! looks_like_number( $price ) ) {
            die("Error: This cask_price doesn't look like a number: $price\n");
        }
        # Assumes price is in the configured default currency.
   	    $caskman->set_column('price', $self->parse_price( $price ));
    }

    return;
}

sub assign_cellar_number {

    my ( $self, $caskman, $id ) = @_;

    if ( defined $id ) {
        if ( ! looks_like_number( $id ) ) {
            die("Error: This cask_cellar_id doesn't look like a number: $id\n");
        }
	$caskman->set_column('internal_reference', $id);
    }

    return;
}

sub assign_stillage_location {

    my ( $self, $caskman, $loc ) = @_;

    my $stillage = $self->database->resultset('StillageLocation')
                                  ->find({ festival_id => $self->festival->id(),
                                           description => $loc })
                                      or die(qq{Error: Stillage location "$loc" }.
                                                 qq{not found.\n});
    my $caskloc = $caskman->get_column('stillage_location_id');
    if ( ! defined $caskloc || $caskloc != $stillage->stillage_location_id ) {
        if ( $self->allow_stillage_move ) { # Initial stillage assignment only.
            $caskman->set_column('stillage_location_id',
                              $stillage->stillage_location_id());
        }
        else {
            push @{ $self->_errors },
                sprintf("Error: Attempting to move cask %s between stillages.",
                        $caskman->cellar_reference);
        }
    }

    return;
}

sub assign_cask_graveyard {

    my ( $self, $caskman, $graveyard ) = @_;

    if ( defined $graveyard ) {
        if ( length($graveyard) > 32 ) {
            die("Error: cask_graveyard location too long (max 32 chars).\n");
        }
    	$caskman->set_column('cask_graveyard', $graveyard);
    }

    return;
}

sub update_caskman {

    my ( $self, $caskman, $row ) = @_;

    # First deal with stillage location. This is required
    # to prevent one well-meaning cellar person from
    # inadvertently screwing with another stillage's info.
    my $loc = $row->{ 'stillage_location' };
    if ( ! defined $loc ) {
        die("Error: stillage_location not defined.") if $self->require_stillage_loc;
    }
    else {
	$self->assign_stillage_location( $caskman, $loc );
    }

    # Cask price.
    if ( my $price = $row->{ 'cask_price' } ) {
        $self->assign_cask_price($caskman, $price);
    }
    
    # Cask graveyard.
    if ( my $graveyard = $row->{ 'cask_graveyard' } ) {
        $self->assign_cask_graveyard($caskman, $graveyard);
    }
    
    # Cellar id ("internal_reference").
    if ( my $id = $row->{ 'cask_cellar_id' } ) {
        $self->assign_cellar_number($caskman, $id);
    }
    
    # Stillage bay.
    if ( my $bay = $row->{ 'stillage_bay' } ) {
        if ( defined $bay ) {
            if ( ! looks_like_number( $bay ) ) {
                die("Error: This stillage_bay doesn't look like a number: $bay\n");
            }
            $caskman->set_column('stillage_bay', $bay);
        }
    }

    # Bay position.
    if ( my $baypos = $row->{ 'bay_position' } ) {
        my $pos = $self->database->resultset('BayPosition')
            ->find({ description => $baypos })
                or die(qq{Error: Bay position "$baypos" not found.});
        $caskman->set_column('bay_position_id',
                          $pos->bay_position_id());
    }

    # Vented, Tapped, Ready...
    my %statmap = ( 'vented'    => 'is_vented',
                    'tapped'    => 'is_tapped',
                    'ready'     => 'is_ready',
                    'condemned' => 'is_condemned' );
    my $cask = $caskman->casks()->first();
    while ( my ( $col, $dbcol ) = each %statmap ) {
        my $value = $row->{ $col };
        if ( defined $value && $value ne q{} ) {
            if ( ! $cask ) {
                die("Attempting to set a concrete cask status"
                        . " on a virtual cask (has it arrived yet?).")
            }
            $cask->set_column($dbcol, $self->parse_boolean($value));
        }
    }

    $cask->update() if $cask;
    $caskman->update();

    return;
}

sub load {

    my ( $self ) = @_;

    # Find header line.
    my $header = $self->get_headers();

    ## Die on unrecognised columns.
    foreach my $col ( @$header ) {
        unless ( first { $col eq $_ } qw(cask_festival_id cask_cellar_id
                                         stillage_location stillage_bay
                                         bay_position vented tapped ready
                                         condemned cask_price cask_graveyard) ) {
            die("Unrecognised column heading: $col\n");
        }
    }

    ## Run the entire load in a single transaction.
    eval {
        $self->database->txn_do(
            sub {
                
                CASK:
                while ( my $line = $self->getline() ) {
                    my $lstr = join('', @$line);
                    next CASK if $lstr =~ /^\s*#/;  # skip comments
                    
                    my %row;
                    @row{ @$header } = @$line;
                    
                    my $cfid = $row{ 'cask_festival_id' };
                    unless ( defined $cfid ) {
                        warn("Row does not contain cask_festival_id. Skipping.\n");
                        next CASK;
                    }
                    
                    my $caskman = $self->database->resultset('CaskManagement')
                        ->find({ festival_id      => $self->festival->id(),
                                 cellar_reference => $cfid })
                            or die(qq{Error: CaskManagement with cellar_reference "$cfid" }
                                       . qq{not found.\n});

                    $self->update_caskman( $caskman, \%row );
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
        die(qq{Errors encountered during load (database not changed):\n\n$@});
    }
    else {
        $self->confirm_eof();
        warn("Cask information successfully loaded.\n");
    }

    return;
}

package main;

sub parse_args {

    my ( $datafile, $allow_stillage_move, $force_load, $want_help );

    GetOptions(
	"i|input=s"    => \$datafile,
	"a|allow"      => \$allow_stillage_move,
	"f|force"      => \$force_load,
        "h|help"       => \$want_help,
    );

    if ($want_help) {
        pod2usage(
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 1,
        );
    }

    unless ( $datafile ) {
        pod2usage(
            -message => qq{Please see "$0 -h" for further help notes.},
            -exitval => 255,
            -output  => \*STDERR,
            -verbose => 0,
        );
    }

    my $config = BeerFestDB::Web->config();

    return( $config, $datafile, $allow_stillage_move, $force_load );
}

my ( $config, $datafile, $allow_stillage_move, $force_load ) = parse_args();

my $schema = BeerFestDB::ORM->connect( @{ $config->{'Model::DB'}{'connect_info'} } );

my $updater = CaskUpdater->new( database            => $schema,
                                csv_file            => $datafile,
                                allow_stillage_move => $allow_stillage_move,
                                require_stillage_loc => not $force_load );

$updater->load();

__END__

=head1 NAME

update_cask_details.pl

=head1 SYNOPSIS

 update_cask_details.pl -i tab_delimited_file.csv

=head1 DESCRIPTION

Local CBF-specific script used to update cask cellar ID, stillage
location, bay number and position once stillaging is complete.

=head1 OPTIONS

=head2 -a

A flag indicating whether or not to allow casks to be automatically
moved between stillages (default: no).

=head2 -f

A flag indicating that load should be attempted in the absence of the
stillage location info. Not recommended for general use (default: no).

=head2 -i

The file containing cask details. This should be in tab-delimited
format and contain the following headings:

=over 2

=item cask_festival_id

REQUIRED. The unique identifier for the cask within the festival.

=item cask_cellar_id

OPTIONAL. The cask cellar number; i.e. the number of the cask within the gyle,
typically in order of sale. For example, if you have six casks of a given beer,
they would most likely be numbered 1 to 6 in this column.

=item stillage_location

REQUIRED. The name of the stillage upon which the cask rests. These
locations must already have been registered in the database. Note that
this column is required specifically to avoid accidental cross-talk
between cellar teams.

=item stillage_bay

OPTIONAL. The number of the bay on the stillage. Currently only constrained to
being an integer.

=item bay_position

OPTIONAL. The position of the cask within the bay. This must conform to the
standard list registered in the bay_position table (e.g. "Top Front",
"Bottom Back").

=item vented

OPTIONAL. Indicates whether the cask has been vented. Code this as '1'
(or any 'true' value in perl, i.e. not zero) to indicate that the cask
has been vented. A zero ('0') in this column will be interpreted as
indicating that the cask is not vented; this can be used to correct
errors in the database. A blank value will be ignored.

=item tapped

OPTIONAL. Whether the cask has been tapped or not. See the notes under 'vented' for details.

=item ready

OPTIONAL. Whether the cask is ready to serve. See the notes under 'vented' for details.

=item condemned

OPTIONAL. Whether the cask has been condemned. See the notes under 'vented' for details.

=item cask_price

OPTIONAL. The original purchase price of the cask. This should
be a value in pounds.

=item cask_graveyard

OPTIONAL. The location of the cask graveyard. This is a free text
field, 32 characters or less. Using fewer characters is recommended
to avoid truncation on the cask labels.

=back

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

