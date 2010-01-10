# $Id$

package BeerFestDB::Dumper::OODoc;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use OpenOffice::OODoc;

use Data::Dumper;

our $VERSION = '0.02';

extends 'BeerFestDB::Dumper';

# Output filename
has 'filename' => ( is       => 'ro',
                    isa      => 'Str',
                    required => 1 );

# Pre-existing template document
has 'template' => ( is       => 'ro',
                    isa      => 'Str',
                    required => 1 );

# The OODoc section of the main beerfestdb_web.yml config file.
has 'config'   => ( is       => 'ro',
                    isa      => 'HashRef',
                    required => 1 );

# These are used internally to track the document container, content and styles.
has '_container' => ( is       => 'rw',
                     isa      => 'OpenOffice::OODoc::File',
                     required => 0 );

has '_content'   => ( is       => 'rw',
                     isa      => 'OpenOffice::OODoc::Document',
                     required => 0 );

has '_styles'    => ( is       => 'rw',
                     isa      => 'OpenOffice::OODoc::Document',
                     required => 0 );

sub BUILD {

    my ( $self, $params ) = @_;

    my $container;

    if ( -f $self->filename ) {

        # Append
        $container = odfContainer( $self->filename );
    }
    else {

        # Create
        $container = odfContainer( $self->filename,
                                   create => 'text' );
    }
    die("Unable to create ODF document") unless $container;

    $self->_container( $container );
    $self->_content( odfDocument( container => $container ) );
    $self->_styles( odfDocument( container => $container, part => 'styles' ) );

    my $style = $self->_parse_template_styles();

    return;
}

sub _parse_template_styles {

    my ( $self ) = @_;

    my $styles = odfDocument( file => $self->template, part => 'styles' );

    # Note that we only copy over our desired styles as specified in
    # the config file. This will hopefully avoid the build-up of
    # crufty style-ridden documents.
    my @wanted = values %{ $self->config->{'styles'} };

    foreach my $name ( @wanted ) {
        my $style = $styles->getStyleElement($name)
            or croak(qq{Error: Template document must define a "$name" style.\n});
        unless ( $self->_styles->getStyleElement( $name ) ) {
            $self->_styles->createStyle( $name,
                                         family    => 'paragraph',
                                         parent    => 'Standard',
                                         prototype => $style);
        }
    }

    return;
}

sub dump {

    my ( $self, $casks ) = @_;

    unless ( $casks ) {
        $casks = $self->select_festival_casks();
        $casks = $self->unique_casks( $casks );
    }

    my ( %caskinfo, %brewerinfo );
    foreach my $cask ( @$casks ) {
        my $brewer = $cask->gyle_id->company_id;
        my $beer   = $cask->gyle_id->product_id;
        $caskinfo{$brewer->name}{$beer->name} = {
            abv         => $cask->gyle_id->abv,
            style       => $beer->product_style_id ? $beer->product_style_id->description : q{N/A},
            description => $beer->description || q{Unknown at time of press.},
        };
        $brewerinfo{$brewer->name}{'location'} = $brewer->loc_desc || q{Unknown location};
    }

    foreach my $brewer ( sort keys %caskinfo ) {
        $self->_content->appendParagraph(
            text    => $brewer,
            style   => $self->config->{'styles'}{'brewery_name'},
        );
        $self->_content->appendParagraph(
            text    => $brewerinfo{$brewer}{'location'},
            style   => $self->config->{'styles'}{'brewery_location'},
        );
        foreach my $beer ( sort keys %{ $caskinfo{$brewer} } ) {
            my $beerinfo = $caskinfo{$brewer}{$beer};
            $self->_content->appendParagraph(
                text    => sprintf(
                    "%s\t%d%%",
                    $beer,
                    $beerinfo->{abv},
                ),
                style   => $self->config->{'styles'}{'beer_name'},
            );
        }
    }

    return;
}

sub DEMOLISH {

    my ( $self ) = @_;

    $self->_container->save;

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

