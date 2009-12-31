# $Id$

package BeerFestDB::Dumper::OODoc;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use OpenOffice::OODoc;

our $VERSION = '0.01';

extends 'BeerFestDB::Dumper';

# Pre-existing file.
has 'filename' => ( is       => 'ro',
                    isa      => 'Str',
                    required => 1 );

sub dump {

    my ( $self, $casks ) = @_;

    unless ( $casks ) {
        $casks = $self->select_festival_casks();
        $casks = $self->unique_casks( $casks );
    }

    my $document;

    if ( -f $self->filename ) {

        # Append
        $document = odfDocument( file   => $self->filename );
    }
    else {

        # Create
        $document = odfDocument( file   => $self->filename,
                                 create => 'text' );
    }
    die("Unable to create ODF document") unless $document;

    my %caskinfo;
    foreach my $cask ( @$casks ) {
        my $brewer = $cask->gyle_id->company_id;
        my $beer   = $cask->gyle_id->product_id;
        $caskinfo{$brewer->name}{$beer->name} = {
            abv         => $cask->gyle_id->abv,
            style       => $beer->product_style_id ? $beer->product_style_id->description : q{N/A},
            description => $beer->description || q{Unknown at time of press.},
        };
    }

    foreach my $brewer ( sort keys %caskinfo ) {
        $document->appendParagraph(
            text    => $brewer,
            style   => 'Heading 4'
        );
        foreach my $beer ( sort keys %{ $caskinfo{$brewer} } ) {
            my $beerinfo = $caskinfo{$brewer}{$beer};
            $document->appendParagraph(
                text    => sprintf(
                    "%s     %d%%  (%s)",
                    $beer,
                    $beerinfo->{abv},
                    $beerinfo->{style},
                ),
                style   => 'Heading 6'
            );
            $document->appendParagraph(
                text    => $beerinfo->{description},
                style   => 'Text body indent'
            );
        }
    }

    $document->save;

    return;
}

1;
__END__

=head1 NAME

BeerFestDB::Dumper::OODoc - Export data to ODF format.

=head1 SYNOPSIS

 use BeerFestDB::Dumper::OODoc;
 
 # $rs is a DBIx::Class::ResultSet; @logos is an array of image file names.
 my $t = BeerFestDB::Dumper::OODoc->new();
 $t->dump( $rs );

=head1 DESCRIPTION

This module describes a Moose class which can be used to process Cask
resultsets through a given Template Toolkit template. This can be used
to generate cask-end signs, HTML listings of the available beers,
conceivably even a full beer festival programme.

=head2 OPTIONS

=over 2

=item filename

The name of the file to be created. If this file already exists, new
information will be appended to it.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper>, L<BeerFestDB::Dumper::Template>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tim F. Rayner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

Probably.

=cut

