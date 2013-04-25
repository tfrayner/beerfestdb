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

sub unique_casks {

    my ( $self ) = @_;

    my $casks = $self->festival_casks();

    my %unique;
        
    foreach my $cask ( @$casks ) {
        my $gyle = $cask->gyle_id();
        my $key = join(':', $gyle->company_id, $gyle->festival_product_id,
                       $cask->cask_management_id->bar_id || q{});
        $unique{ $key } = $cask;
    }

    return [ values %unique ];
}

sub dump {

    my ( $self, $casks ) = @_;

    unless ( $casks ) {
        $casks = $self->unique_casks();
    }

    my ( %barinfo, %brewerinfo, %product_stillaged );

    # All beers present in casks on a stillage are handled here.
    foreach my $cask ( @$casks ) {
        my $caskman = $cask->cask_management_id;
        my $bar = $caskman->bar_id() ? $caskman->bar_id()->description()
                : $caskman->stillage_location_id() ? $caskman->stillage_location_id()->description()
                : q{};
        my $brewer = $cask->gyle_id->company_id;
        my $beer   = $cask->gyle_id->festival_product_id()->product_id;
        $barinfo{$bar}{$brewer->name}{$beer->name} = {
            abv         => $cask->gyle_id->abv || $beer->nominal_abv,
            style       => $beer->product_style_id ? $beer->product_style_id->description : q{N/A},
            description => $beer->description, #q{Tasting notes unavailable at time of press.},
        };
        $brewerinfo{$brewer->name}{'location'} = $brewer->loc_desc || q{Unknown location};
        $product_stillaged{ $beer->get_column('product_id') }++;
    }

    # Deal with beers not stillaged (e.g. if we're dealing with them
    # only at the FestivalProduct level).
    foreach my $beer ( @{ $self->festival_products } ) {
        unless ( $product_stillaged{ $beer->get_column('product_id') } ) {
            my $brewer = $beer->company_id;
            $barinfo{'Other Bars'}{$brewer->name}{$beer->name} = {
                abv         => $beer->nominal_abv,
                style       => $beer->product_style_id ? $beer->product_style_id->description : q{N/A},
                description => $beer->description,
            };
            $brewerinfo{$brewer->name}{'location'} = $brewer->loc_desc || q{Unknown location};
        }
    }

    # Write out the data to the template document.
    while ( my ( $bar, $caskinfo ) = each %barinfo ) {
        warn("Printing bar info: $bar\n");
        if ( $bar ) {
            $self->_content->appendParagraph(
                text    => $bar,
                style   => $self->config->{'styles'}{'bar_name'},
            );            
        }
        foreach my $brewer ( sort keys %$caskinfo ) {
            warn("  Printing details for $brewer...\n");
            $self->_content->appendParagraph(
                text    => $brewer,
                style   => $self->config->{'styles'}{'brewery_name'},
            );
            $self->_content->appendParagraph(
                text    => $brewerinfo{$brewer}{'location'},
                style   => $self->config->{'styles'}{'brewery_location'},
            );
            foreach my $beer ( sort keys %{ $caskinfo->{$brewer} } ) {
                my $beerinfo = $caskinfo->{$brewer}{$beer};
                my $line = $beerinfo->{abv} ? sprintf("%s\t%.1f%%",
                                                      $beer,
                                                      $beerinfo->{abv} )
                    : sprintf("%s\t%s %%", $beer, 'Unknown');
                $self->_content->appendParagraph(
                    text    => $line,
                    style   => $self->config->{'styles'}{'beer_name'},
                );
                if ( $self->config->{'dump_tasting_notes'} && $beerinfo->{'description'} ) {
                    $self->_content->appendParagraph(
                        text    => $beerinfo->{'description'},
                        style   => $self->config->{'styles'}{'beer_notes'},
                    );
                }
            }
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
 
 # $casks is an arrayref of DBIx::Class::Row objects;
 my $t = BeerFestDB::Dumper::OODoc->new();
 $t->dump( $casks );

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

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

