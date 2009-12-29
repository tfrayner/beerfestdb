# $Id$

package BeerFestDB::Dumper;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

has 'database'  => ( is       => 'ro',
                     isa      => 'DBIx::Class::Schema',
                     required => 1 );

sub select_festival_casks {

    my ( $self ) = @_;

    # Just retrieve the casks for the festival in question. We need an
    # interactive menu here.
    my @festivals = $self->database->resultset('Festival')->all();

    my $wanted;

    SELECT:
    {
        warn("Please select the beer festival of interest:\n\n");
        foreach my $n ( 1..@festivals ) {
            my $fest = $festivals[$n-1];
            warn(sprintf("  %d: %d %s\n", $n, $fest->year, $fest->name));
        }
        warn("\n");
        chomp(my $select = <STDIN>);
        redo SELECT unless ( looks_like_number( $select )
                                 && ($wanted = $festivals[ $select-1 ]) );
    }
    
    my @casks = $wanted->search_related('casks')->all();

    return \@casks;
}

sub unique_casks {

    my ( $self, $casks ) = @_;

    my ( @unique, %cask_seen );
    foreach my $cask ( @$casks ) {
        my $beer   = $cask->gyle_id()->product_id()->name();
        my $brewer = $cask->gyle_id()->company_id()->name();
        push @unique, $cask unless (
            $cask_seen{ $brewer }{ $beer }++
        );
    }

    return \@unique;
}

sub format_price {

    my ( $self, $price, $format ) = @_;

    return 'STAFF' unless $price;

    my @digits = split //, $price;

    my $formatted = q{};

    POS:
    foreach my $pos ( 1..length($format) ) {
        my $f = substr($format, -$pos, 1);
        if ( $f !~ /[#0]/ ) {
            $formatted = $f . $formatted;
            next POS;
        }
        my $num = pop @digits;
        last POS if ( $f eq '#' && ! defined $num );
        if ( $f eq '0' ) {
            $num ||= 0;
            $formatted = $num . $formatted;
        }
        else {
            die(qq{Error: Unrecognised formatting symbol: "$f".\n});
        }
    }

    return $formatted;
}

1;
__END__

=head1 NAME

BeerFestDB::Dumper - Abstract superclass for data dumper classes.

=head1 SYNOPSIS

 use Moose
 extends 'BeerFestDB::Dumper';

=head1 DESCRIPTION

This is an abstract class designed to be extended by the various
Dumper subclasses.

=head2 METHODS

=over 2

=item select_festival_casks

A method which will interactively ask the user for the festival of
interest, and return a list of casks for that festival.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper::Template>, L<BeerFestDB::Dumper::OODoc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tim F. Rayner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

Probably.

=cut

