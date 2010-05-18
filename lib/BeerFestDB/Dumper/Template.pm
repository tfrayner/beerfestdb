# $Id$

package BeerFestDB::Dumper::Template;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);
use Storable qw(dclone);
use Template;
use POSIX qw(ceil);

our $VERSION = '0.01';

extends 'BeerFestDB::Dumper';

has 'template'   => ( is       => 'ro',
                      isa      => 'Str',
                      required => 1 );

has 'filehandle' => ( is       => 'ro',
                      isa      => 'FileHandle',
                      required => 1,
                      default  => sub { \*STDOUT } );

has 'logos'      => ( is       => 'ro',
                      isa      => 'ArrayRef',
                      required => 1,
                      default  => sub { [] } );

has 'dump_class'  => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1,
                       default  => 'product' );

sub BUILD {

    my ( $self, $params ) = @_;

    my $class = $params->{'dump_class'};
    if ( defined $class ) {
        unless ( first { $class eq $_ } qw(cask gyle product) ) {
            confess(qq{Error: Unsupported dump class "$class"});
        }
    }

    return;
}

sub product_hash {

    my ( $self, $product ) = @_;

    my $fest = $self->festival();
    my $fp   = $product->search_related('festival_products',
					{ festival_id => $fest->festival_id })->first();

    # N.B. Changes here need to be documented in the POD.
    my %prodhash = (
        brewery  => $product->company_id->name(),
	location => $product->company_id->loc_desc(),
        product  => $product->name(),
        style    => $product->product_style_id()
                    ? $product->product_style_id()->description() : q{},
        category => $product->product_category_id()->description(),
        abv      => $product->nominal_abv(),
        sale_volume => $fp->sale_volume_id()->sale_volume_description(),
        notes    => $product->description(),
    );

    my $currency = $fp->sale_currency_code();
    my $format   = $currency->currency_format();
    $prodhash{currency} = $currency->currency_symbol();

    $prodhash{price}   = $self->format_price( $fp->sale_price(), $format );
    if ( looks_like_number( $prodhash{price} ) ) {
        $prodhash{half_price}
            = $self->format_price( ceil($fp->sale_price() / 2), $format );
    }
    else {
        $prodhash{half_price} = $prodhash{price};
    }

    return \%prodhash;
}

sub update_gyle_hash {

    my ( $self, $gylehash, $gyle ) = @_;

    # N.B. Changes here need to be documented in the POD.
    $gylehash ||= {};

    # This potentially overwrites the "nominal" ABV from the product
    # table with the *actual* gyle ABV.
    if ( defined $gyle->abv() ) {
        $gylehash->{abv} = $gyle->abv();
    }

    return $gylehash;
}

sub update_cask_hash {

    my ( $self, $caskhash, $cask ) = @_;

    # N.B. Changes here need to be documented in the POD.
    $caskhash ||= {};
    $caskhash->{number} = $cask->internal_reference();

    return $caskhash;
}

sub dump {

    my ( $self ) = @_;

    my ( @template_data, %stillage );
    if ( $self->dump_class eq 'cask' ) {
        foreach my $cask ( @{ $self->festival_casks() } ) {
            my $caskhash = $self->product_hash( $cask->gyle_id()->product_id() );
            $self->update_gyle_hash( $caskhash, $cask->gyle_id() );
            $self->update_cask_hash( $caskhash, $cask );

            push @template_data, $caskhash;

            my $stillage_name = $cask->stillage_location_id()
                                ? $cask->stillage_location_id()->description() : '';
            push @{ $stillage{ $stillage_name } }, $caskhash;
        }
    }
    elsif ( $self->dump_class eq 'gyle' ) {
        foreach my $product ( @{ $self->festival_products } ) {
	    my @gyles =
		$product->search_related('gyles', 
					 { 'casks.festival_id' => $self->festival->id() },
					 {
					     prefetch => { casks => 'festival_id' },
					     join     => { casks => 'festival_id' },
					 });
            foreach my $gyle ( @gyles ) {
                my $gylehash = $self->product_hash( $gyle->product_id() );
                $self->update_gyle_hash( $gylehash, $gyle );

                push @template_data, $gylehash;
            }
        }
    }
    elsif ( $self->dump_class eq 'product' ) {
        foreach my $product ( @{ $self->festival_products() } ) {
            my $prodhash = $self->product_hash( $product );
            push @template_data, $prodhash;
        }
    }
    else {
        confess(sprintf(qq{Attempt to dump data from unsupported class "%s"}, $self->dump_class));
    }

    my $vars = {
        logos      => $self->logos(),
        casks      => \@template_data,
        stillages  => \%stillage,
    };

    # We define a custom title case filter for convenience.
    my $template = Template->new(
	FILTERS => {titlecase => sub { join(' ', map { ucfirst $_ } split / +/, lc($_[0])) }}
    )   or die( "Cannot create Template object: " . Template->error() );

    $template->process($self->template(), $vars, $self->filehandle() )
        or die( "Template processing error: " . $template->error() );

    return;
}

1;
__END__

=head1 NAME

BeerFestDB::Dumper::Template - Export data via Template Toolkit

=head1 SYNOPSIS

 use BeerFestDB::Dumper::Template;
 
 # $rs is a DBIx::Class::ResultSet; @logos is an array of image file names.
 my $t = BeerFestDB::Dumper::Template->new( template => 'template.tt2',
                                            logos    => \@logos );
 $t->dump( $rs );

=head1 DESCRIPTION

This module describes a Moose class which can be used to process Cask
resultsets through a given Template Toolkit template. This can be used
to generate cask-end signs, HTML listings of the available beers,
conceivably even a full beer festival programme.

=head2 DETAILS

Currently the script defines the following variables which may be
referenced in the template:

=over 2

=item casks

A list of cask hashrefs, each of which has the following keys:

=over 2

=item brewery

The original brewer of the product.

=item location

The location of the brewery.

=item product

The name of the beer, cider, or whatever.

=item number

The internal reference number for this cask.

=item category

The product category ("beer", "cider" etc.).

=item style

The product style ("Stout", "Best Bitter", "Medium Sweet" etc.).

=item notes

A description of the product (e.g., beer tasting notes).

=item abv

The ABV, obviously.

=item currency

The currency used for sales.

=item price

The price per sale unit (typically price per pint).

=item half_price

The price per half sale unit.

=item sale_volume

The sale unit itself.

=back

=item stillages

A hashref keyed by stillage names linked to arrayrefs of cask hashrefs as
documented above.

=item logos

An arrayref containing the names of image files which can be
referenced in the template to place logos etc.

=back

=head2 OPTIONS

=over 2

=item template

The template file to use.

=item filehandle

The output filehandle (default STDOUT).

=item logos

An arrayref containing logo file names to pass through to the templates.

=item dump_class

A string indicating the level at which to dump out data. Can be one of
"cask", "gyle" or "product".

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper>, L<BeerFestDB::Dumper::OODoc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tim F. Rayner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

Probably.

=cut

