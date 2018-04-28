#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2013 Tim F. Rayner
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

package BeerFestDB::Dumper::Template;

use 5.008;

use strict; 
use warnings;

use Moose;

use Carp;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first any);
use Storable qw(dclone);
use Cwd;
use File::Spec::Functions qw(catfile);
use Template;
use POSIX qw(ceil);
use utf8;

our $VERSION = '0.01';

extends 'BeerFestDB::Dumper';

with 'BeerFestDB::DipMunger';

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

has 'filters'    => ( is       => 'ro',
                      isa      => 'ArrayRef',
                      required => 1,
                      default  => sub { [] } );

has 'dump_class'  => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1,
                       default  => 'product' );

has 'split_output' => ( is       => 'ro',
                        isa      => 'Bool',
                        required => 1,
                        default  => 0 );

has 'output_dir'  => ( is       => 'ro',
                       isa      => 'Str',
                       required => 1,
                       default  => getcwd );

has 'overwrite'   => ( is       => 'ro',
                       isa      => 'Bool',
                       required => 1,
                       default  => 0 );

has 'skip_unpriced' => ( is       => 'ro',
                         isa      => 'Bool',
                         required => 1,
                         default  => 0 );

sub BUILD {

    my ( $self, $params ) = @_;

    my $class = $params->{'dump_class'};
    if ( defined $class ) {
        unless ( first { $class eq $_ } qw(cask cask_management gyle
                                           product product_order distributor) ) {
            confess(qq{Error: Unsupported dump class "$class"});
        }
    }

    my $outdir = $params->{'output_dir'};
    if ( defined $params->{'filehandle'} && defined $params->{'split_output'} ) {

        warn(q{Warning: filehandle attribute used in conjunction with split_output;} .
             q{ this does not make sense. Script will ignore the filehandle.\n});
    }

    if ( defined $outdir && ! -e $outdir ) {
        mkdir $outdir;
    }

    return;
}

sub _sanitise_filename {

    my ( $self, $tag ) = @_;

    $tag =~ s/['"]//g;
    $tag =~ s/\&/and/g;
    $tag =~ s/[^[:alnum:]]+/_/g;

    return $tag;
}

sub allergen_hash {

    my ( $self, $product ) = @_;

    # Return a hashref keyed by allergen; values are 1=present,
    # 0=absent, undef=unknown, as stored in the database.

    my %allergen_data;

    foreach my $allergen ( $self->database->resultset('ProductAllergenType')->all() ) {
        my $pa = $allergen->search_related(
            'product_allergens',
            { product_id => $product->product_id })->first();
        $allergen_data{ $allergen->description() } = $pa ? $pa->present : undef;
    }

    return \%allergen_data;
}

sub product_hash {

    my ( $self, $product, $prodhash ) = @_;

    $prodhash ||= {};

    my $fest = $self->festival();
    my $fp   = $product->search_related('festival_products',
					{ festival_id => $fest->festival_id })->first();

    my $tag = $self->_sanitise_filename(sprintf("%s %s",
                                                $product->company_id->name(),
                                                $product->name()));

    # N.B. Changes here need to be documented in the POD.
    $prodhash->{brewery}  = $product->company_id->name();
    $prodhash->{location} = $product->company_id->loc_desc();
    $prodhash->{product}  = $product->name();
    $prodhash->{style}    = $product->product_style_id()
	                ? $product->product_style_id()->description() : q{};
    $prodhash->{category} = $product->product_category_id()->description();
    $prodhash->{abv}      = $product->nominal_abv();
    $prodhash->{notes}    = $product->description();
    $prodhash->{allergens} = $self->allergen_hash( $product );
    $prodhash->{_split_export_tag} = $tag;

    # Handle FestivalProduct data here.
    if ( $fp ) {
        $prodhash->{sale_volume} = $fp->sale_volume_id()->description();
        my $currency = $fp->sale_currency_id();
        my $format   = $currency->currency_format();
        $prodhash->{currency} = $currency->currency_symbol();

        # The formatted_price option is great if you just want to display
        # the price in the local format. However, if you need to do any
        # calculations then use price and the price_format filter
        # below. This reduces the risk of floating-point errors.
	# UPDATE: commented out this line as the formatting code breaks on large price values.
#        $prodhash->{formatted_price} = $self->format_price( $fp->sale_price(), $format );
        $prodhash->{price} = $fp->sale_price(); # typically in pennies (GBP).
    }

    return $prodhash;
}

sub order_hash {

    my ( $self, $order ) = @_;

    my $fest = $self->festival();

    my $config = BeerFestDB::Web->config();
    my $default_meas_unit = $self->database->resultset('ContainerMeasure')->find({
        description => $config->{'default_measurement_unit'},
    }) or die("Unable to retrieve default measurement unit; check config settings.");

    my $local_cask_size = $order->container_size_id->container_volume();
    my $cask_measure    = $order->container_size_id->container_measure_id();

    my %orderhash = (
        brewery     => $order->product_id->company_id->name(),
        product     => $order->product_id->name(),
        distributor => $order->distributor_company_id->name(),
        cask_size   => $local_cask_size,
        cask_size_unit => $cask_measure->symbol(),
        cask_size_name => $order->container_size_id->description(),
        cask_size_std  => $local_cask_size
                        * ( $cask_measure->litre_multiplier() /
                            $default_meas_unit->litre_multiplier() ),
	dispense_method => $order->container_size_id->dispense_method_id->description(),
        cask_count  => $order->cask_count(),
        is_sale_or_return => $order->is_sale_or_return(),
        is_disposable     => $order->container_size_id->dispense_method_id->is_disposable(),
        nominal_abv => $order->product_id->nominal_abv(),
        _split_export_tag => $order->product_order_id(),
    );

    my $currency = $order->currency_id();
    my $format   = $currency->currency_format();
    $orderhash{currency} = $currency->currency_symbol();
#    use Data::Dumper; warn Dumper [$format, $order->advertised_price()];
#    $orderhash{price}    = $self->format_price( $order->advertised_price(), $format ); FIXME

    return \%orderhash;
}

sub _retrieve_sales_contact {

    my ( $self, $dist ) = @_;

    my $ct = $self->database()->resultset('ContactType')->find({ description => 'Sales' })
        or croak(qq{Cannot find 'Sales' ContactType in database.});

    my $contact = $dist->search_related('contacts', {contact_type_id => $ct->id})->first()
        or croak(sprintf(qq{Cannot find 'Sales' contact for '%s'.}, $dist->name()));

    return $contact;
}

sub distributor_hash {

    my ( $self, $dist ) = @_;

    my $fest       = $self->festival();
    my $orderbatch = $self->order_batch();

    my $tag = $self->_sanitise_filename(sprintf("%s %s",
                                                $orderbatch->description(),
                                                $dist->name()));

    my %disthash = (
        id         => $dist->id(),
        name       => $dist->name(),
        full_name  => $dist->full_name(),
        batch_id   => $orderbatch->id(),
        _split_export_tag => $tag,
    );

    # Some distributor-level template dumps have no need for sales
    # contact data (e.g. delivery checklists) so we only warn here.
    my $contact;
    eval { $contact = $self->_retrieve_sales_contact( $dist ) };
    if ( $@ ) {
        warn( $@ );
    }
    else {
        $disthash{'address'}  = $contact->street_address();
        $disthash{'postcode'} = $contact->postcode();
    }

    my $order_rs
        = $dist->search_related('product_orders',
                                { order_batch_id => $orderbatch->id(),
                                  is_final       => 1 });
    
    my %orderhashlist;
    while ( my $order = $order_rs->next() ) {
        my $product = $order->product_id->name();
        my $brewery = $order->product_id->company_id->name();
        push @{ $orderhashlist{$brewery}{$product} }, $self->order_hash( $order );
    }
    $disthash{'orders'} = \%orderhashlist;

    return \%disthash;
}

sub update_gyle_hash {

    my ( $self, $gylehash, $gyle ) = @_;

    # N.B. Changes here need to be documented in the POD.
    $gylehash ||= {};
    $gylehash->{_split_export_tag} = $gyle->gyle_id();

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
    $caskhash->{_split_export_tag} = $cask->cask_id();
    $caskhash->{dips}         = $self->munge_dips( $cask );
    $caskhash->{comment}      = $cask->comment();
    $caskhash->{is_condemned} = $cask->is_condemned();

    return $caskhash;
}

sub update_caskman_hash {

    my ( $self, $caskmanhash, $caskman ) = @_;

    my $config = BeerFestDB::Web->config();
    my $default_meas_unit = $self->database->resultset('ContainerMeasure')->find({
        description => $config->{'default_measurement_unit'},
    }) or die("Unable to retrieve default measurement unit; check config settings.");

    my $local_cask_size = $caskman->container_size_id->container_volume();
    my $cask_measure    = $caskman->container_size_id->container_measure_id();

    # N.B. Changes here need to be documented in the POD.
    $caskmanhash ||= {};
    $caskmanhash->{_split_export_tag} = $caskman->cask_management_id();
    $caskmanhash->{number}      = $caskman->internal_reference();
    $caskmanhash->{festival_id} = $caskman->cellar_reference();
    $caskmanhash->{cask_size}   = $local_cask_size;
    $caskmanhash->{cask_size_unit} = $cask_measure->symbol();
    $caskmanhash->{cask_size_name} = $caskman->container_size_id->description();
    $caskmanhash->{cask_size_std}  = $local_cask_size
                                   * ( $cask_measure->litre_multiplier() /
                                       $default_meas_unit->litre_multiplier() );
    $caskmanhash->{dispense_method} = $caskman->container_size_id->dispense_method_id->description();
    $caskmanhash->{is_disposable} = $caskman->container_size_id->dispense_method_id->is_disposable();
    $caskmanhash->{is_sale_or_return} = $caskman->is_sale_or_return();
    $caskmanhash->{stillage_bay} = $caskman->stillage_bay();
    $caskmanhash->{bay_position} = $caskman->bay_position_id
	  ? $caskman->bay_position_id->description() : q{};
    my $stillage_loc = $caskman->stillage_location_id();
    $caskmanhash->{stillage_location} = $stillage_loc ? $stillage_loc->description() : q{};
    $caskmanhash->{order_batch}  = $caskman->product_order_id
  	  ? $caskman->product_order_id->order_batch_id->description() : 'Unknown';
    $caskmanhash->{distributor}  = $caskman->distributor_company_id
          ? $caskman->distributor_company_id->name() : 'Untracked';

    return $caskmanhash;
}

sub is_user_filtered {

    my ( $self, $objhash ) = @_;

    # Filters are stored as an arrayref of arrayrefs.
    foreach my $filter ( @{ $self->filters } ) {
        my ( $key, $value, $count ) = @$filter;
        if ( exists($objhash->{ $key }) && $objhash->{ $key } eq $value ) {
            $filter->[2]++;
            return 1;
        }
    }
    return 0;
}

sub dump {

    my ( $self ) = @_;

    my ( @template_data, %stillage, @dip_batches );
    if ( $self->dump_class eq 'cask' ) {
        foreach my $cask ( @{ $self->festival_casks() } ) {
            my $caskhash = $self->product_hash(
                $cask->gyle_id()->festival_product_id()->product_id()
            );
            $self->update_gyle_hash( $caskhash, $cask->gyle_id() );
            $self->update_caskman_hash( $caskhash, $cask->cask_management_id() );
            $self->update_cask_hash( $caskhash, $cask );

            push @template_data, $caskhash;

            my $stillage_loc  = $cask->cask_management_id()->stillage_location_id();
            my $stillage_name = $stillage_loc ? $stillage_loc->description() : q{};

            push @{ $stillage{ $stillage_name } }, $caskhash;
        }

        my $batches = $self->festival
                           ->search_related('measurement_batches',
                                            undef,
                                            { order_by => { -asc => 'measurement_time' } });
        while ( my $batch = $batches->next() ) {
            push @dip_batches, { id   => $batch->id(),
                                 name => $batch->description() };
        }
    }
    elsif ( $self->dump_class eq 'cask_management' ) {
        foreach my $caskman ( @{ $self->festival_cask_managements() } ){
            my $caskmanhash = {};
            my ( $po, $casks );
            if ( $po = $caskman->product_order_id() ) {
                $caskmanhash = $self->product_hash(
                    $po->product_id()
                );
            }
            elsif ( $casks = $caskman->casks() ) { # Actually, There Can Be Only One...
		my $cask = $casks->next();
                $caskmanhash = $self->product_hash( $cask->gyle_id()->festival_product_id()->product_id() );
                $self->update_cask_hash( $caskmanhash, $cask );
            }

            $self->update_caskman_hash( $caskmanhash, $caskman );

            push @template_data, $caskmanhash;
        }
    }
    elsif ( $self->dump_class eq 'gyle' ) {
        foreach my $product ( @{ $self->festival_products } ) {
            my @gyles = $product->search_related('festival_products',
                                                 { festival_id => $self->festival->id() })
                                ->search_related('gyles');
            foreach my $gyle ( @gyles ) {
                my $gylehash = $self->product_hash( $gyle->festival_product_id()->product_id() );
                $self->update_gyle_hash( $gylehash, $gyle );

                push @template_data, $gylehash;

                # For typical use-case this might be better done by bar rather than stillage FIXME.
                my %stillage_seen;
                STILLAGE:
                foreach my $caskman ( $gyle->search_related('casks')
                                           ->search_related('cask_management_id',
                                                            { festival_id => $self->festival->id() }) ) { 
                    my $stillage_name = $caskman->stillage_location_id()
                        ? $caskman->stillage_location_id()->description() : '';
                    next STILLAGE if $stillage_seen{ $stillage_name }++;
                    push @{ $stillage{ $stillage_name } }, $gylehash;
                }
            }
        }
    }
    elsif ( $self->dump_class eq 'product' ) {
        foreach my $product ( @{ $self->festival_products() } ) {
            my $prodhash = $self->product_hash( $product );
            push @template_data, $prodhash;
        }
    }
    elsif ( $self->dump_class eq 'product_order' ) {
        foreach my $order ( @{ $self->festival_orders() } ) {
            my $orderhash = $self->order_hash( $order );
	    $self->product_hash( $order->product_id(), $orderhash );
            push @template_data, $orderhash;
        }
    }
    elsif ( $self->dump_class eq 'distributor' ) {
        foreach my $dist ( @{ $self->order_batch_distributors() } ) {
            my $disthash = $self->distributor_hash( $dist );
            push @template_data, $disthash;
        }
    }
    else {
        confess(sprintf(qq{Attempt to dump data from unsupported class "%s"}, $self->dump_class));
    }

    # The user may have specified some object properties to filter out of the dump.
    @template_data = grep { ! $self->is_user_filtered($_) } @template_data;
    foreach my $stillage_name ( keys %stillage ) {
        $stillage{ $stillage_name } = [ grep { ! $self->is_user_filtered($_) }
                                            @{ $stillage{ $stillage_name } } ];
    }
    foreach my $filter ( @{ $self->filters } ) {
        my ( $key, $value, $count ) = @$filter;
        if ( (not defined($count)) || $count == 0 ) {
            warn("Warning: Filter expression did not remove any entries: $key=$value\n");
        }
    }

    # Filter out objects without a price available, if desired.
    if ( $self->skip_unpriced ) {
        @template_data = grep { has_nonzero_price($_) } @template_data;
        foreach my $stillage_name ( keys %stillage ) {
            $stillage{ $stillage_name } = [ grep { has_nonzero_price($_) }
                                                @{ $stillage{ $stillage_name } } ];
        }
    }

    # We define some custom filters for convenience.
    my $template = Template->new(
	ABSOLUTE => 1,
	FILTERS => {
            titlecase => sub { join(' ', map { ucfirst $_ } split / +/, lc($_[0])) },
            latexify  => \&filter_to_latex,
            price_format => [ \&rounded_fraction_factory, 1 ],
        }
    )   or die( "Cannot create Template object: " . Template->error() );

    my $vars = {
        logos      => $self->logos(),
        stillages  => \%stillage,
        dip_batches => \@dip_batches,
        dump_class => $self->dump_class(),
    };

    if ( $self->split_output() ) {

        ITEM:
        foreach my $item ( @template_data ) {
            my $export_filename = catfile($self->output_dir,
                                          $item->{_split_export_tag} . ".tex");
            if ( -e $export_filename && ! $self->overwrite ) {
                warn("Output file already exists; will not overwrite. Skipping.\n");
                next ITEM;
            }
            warn(sprintf("Creating output file for %s: %s\n",
                         $self->dump_class(), $item->{_split_export_tag}));
            open(my $export_fh, '>', $export_filename)
                or die("Error: unable to open output file $export_filename.");
            $vars->{'objects'} = [ $item ];
            $template->process($self->template(), $vars, $export_fh )
                or die( "Template processing error: " . $template->error() );
            close($export_fh) or die("$!");
        }
    }
    else {
        $vars->{'objects'} = \@template_data,
        $template->process($self->template(), $vars, $self->filehandle() )
            or die( "Template processing error: " . $template->error() );
    }

    return;
}

sub has_nonzero_price {

    my ( $hashref ) = @_;

    # In case we use a dump class which has no price data, detect that
    # here to reduce potential confusion.
    return ! (exists $hashref->{'price'}) || $hashref->{'price'};
}

sub rounded_fraction_factory {

    # Custom filter to take a fraction of a given price and round it
    # to the nearest 1dp. This is a rather arbitrary threshold but
    # works well for GBP. Note that this may well need fixing to
    # support the full range of currency formats.

    my ( $context, $by, $dp, $denom ) = @_;

    # Price is typically given in pennies, we may want it in
    # pounds. Using $denom=100 would work in such a case.

    # Default settings just formats the price from pennies to pounds.
    $by    ||= 1;
    $denom ||= 100; # Good for GBP, USD and similar.
    if ( ! defined $dp ) { $dp  = 1; } # can be zero

    my $divisor = 10**(2-$dp);

    return sub {

        my ( $text ) = @_;

        my $rounded;
        if ( looks_like_number($text) ) {
            $rounded = ceil($text / ( $by * $divisor )) / ( $denom / $divisor );
        }
        else {
            return $text # pass-through text values.
        }

        return $rounded
    }
}

sub filter_to_latex {

    # This is the core method used by the latexify filter to encode
    # LaTeX control characters and more esoteric characters into
    # something that can be processed by LaTeX.

    my ( $text ) = @_;

    # Common characters.
    $text =~ s/ \{  /\\{/gxms;
    $text =~ s/ \}  /\\}/gxms;
    $text =~ s/ \&  /\\&/gxms;
    $text =~ s/ \%  /\\%/gxms;
    $text =~ s/ \#  /\\#/gxms;
    $text =~ s/ [_] /\\_/gxms;
    $text =~ s/ \$  /\\\$/gxms;
    $text =~ s/ \n  /\\\\/gxms;

    # In the following we try to support both Latin-1 and UTF-8
    # encodings. Note that the UTF-8 substitution requires
    # mysql_enable_utf8 => 1 in the DBD::mysql connection options (see
    # beerfestdb_web.yml).

    # N.B. we're not covering all capitals yet FIXME?

    # Hex representations can be found by running e.g.:
    #    printf "%x", ord('ç')
    # (although make sure you 'use utf8' when doing so).

    # Grave accents.
    $text =~ s/ (?: à | \x{e0} ) /\\`{a}/gxms;
    $text =~ s/ (?: è | \x{e8} ) /\\`{e}/gxms;
    $text =~ s/ (?: ì | \x{ec} ) /\\`{\\i}/gxms;
    $text =~ s/ (?: ò | \x{f2} ) /\\`{o}/gxms;
    $text =~ s/ (?: ù | \x{f9} ) /\\`{u}/gxms;

    # Acute accents.
    $text =~ s/ (?: á | \x{e1} ) /\\'{a}/gxms;
    $text =~ s/ (?: é | \x{e9} ) /\\'{e}/gxms;
    $text =~ s/ (?: í | \x{ed} ) /\\'{\\i}/gxms;
    $text =~ s/ (?: ó | \x{f3} ) /\\'{o}/gxms;
    $text =~ s/ (?: ú | \x{fa} ) /\\'{u}/gxms;

    $text =~ s/ (?: Á | \x{c1} ) /\\'{A}/gxms;
    $text =~ s/ (?: É | \x{c9} ) /\\'{E}/gxms;
    $text =~ s/ (?: Í | \x{cd} ) /\\'{\\I}/gxms;
    $text =~ s/ (?: Ó | \x{d3} ) /\\'{O}/gxms;
    $text =~ s/ (?: Ú | \x{da} ) /\\'{U}/gxms;

    # Circumflex accents.
    $text =~ s/ (?: â | \x{e2} ) /\\^{a}/gxms;
    $text =~ s/ (?: ê | \x{ea} ) /\\^{e}/gxms;
    $text =~ s/ (?: î | \x{ee} ) /\\^{\\i}/gxms;
    $text =~ s/ (?: ô | \x{f4} ) /\\^{o}/gxms;
    $text =~ s/ (?: û | \x{fb} ) /\\^{u}/gxms;

    # Umlauts.
    $text =~ s/ (?: ä | \x{e4} ) /\\"{a}/gxms;
    $text =~ s/ (?: ë | \x{eb} ) /\\"{e}/gxms;
    $text =~ s/ (?: ï | \x{ef} ) /\\"{\\i}/gxms;
    $text =~ s/ (?: ö | \x{f6} ) /\\"{o}/gxms;
    $text =~ s/ (?: ü | \x{fc} ) /\\"{u}/gxms;

    $text =~ s/ (?: Ä | \x{c4} ) /\\"{A}/gxms;
    $text =~ s/ (?: Ë | \x{cb} ) /\\"{E}/gxms;
    $text =~ s/ (?: Ï | \x{cf} ) /\\"{\\I}/gxms;
    $text =~ s/ (?: Ö | \x{d6} ) /\\"{O}/gxms;
    $text =~ s/ (?: Ü | \x{dc} ) /\\"{U}/gxms;

    # Misc.
    $text =~ s/ (?: \£ | \x{a3} ) /\\pounds/gxms;
    $text =~ s/ (?: ç  | \x{e7} ) /\\c{c}/gxms;
    $text =~ s/ (?: ß  | \x{df} ) /\\ss/gxms;
    $text =~ s/ (?: ø  | \x{f8} ) /\\o /gxms;
    $text =~ s/ (?: π  | \x{3c0} ) /\$\\pi\$/gxms;
    $text =~ s/ (?: °  | \x{b0} ) /\$\^\{\\circ\}\$/gxms;

    return $text;
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

(Cask-level export only). The internal reference number for the cask.

=item festival_id

(Cask-level export only). The unique festival ID for the cask.

=item cask_size

(Cask-level export only). The size of the cask.

=item cask_size_unit

(Cask-level export only). The units in which cask_size is reported.

=item cask_size_std

(Cask-level export only). The size of the cask in the currently
configured default_measurement_unit (e.g., gallons).

=item cask_size_name

(Cask-level export only). The cask size name in the database (e.g. "firkin").

=item dispense_method

(Cask-level export only). The cask dispense method (e.g. "cask", "keykeg").

=item cask_count

(Product-order-level export only). The number of casks in the order.

=item category

The product category ("beer", "cider" etc.).

=item style

The product style ("Stout", "Best Bitter", "Medium Sweet" etc.).

=item notes

A description of the product (e.g., beer tasting notes).

=item abv

The ABV, obviously. Depending on context, this is either the nominal
ABV or the actual ABV as linked to a specific product gyle.

=item nominal_abv

(Product-order-level export only). The nominal ABV as advertised.

=item currency

The currency used for sales.

=item price

The price per sale unit (typically price per pint).

=item half_price

The price per half sale unit.

=item sale_volume

The sale unit itself.

=item comment

Free-text notes on the cask.

=item is_condemned

A boolean flag indicating whether the cask has been condemned or not.

=item is_sale_or_return

A boolean flag indicating whether the cask or product order is sale-or-return or not.

=item dips

A hashref of dip measurements keyed by measurement batch ID, fully
filled up to the latest batch containing any dip figures. This
arrayref is populated using the DipMunger role.

=item allergens

A hashref of allergen records, keyed by the name of the allergens. All
allergens stored in the database are represented. Values are
1=present, 0=absent, undef=unknown.

=back

=item stillages

A hashref keyed by stillage names linked to arrayrefs of cask hashrefs as
documented above.

=item logos

An arrayref containing the names of image files which can be
referenced in the template to place logos etc.

=item dip_batches

An arrayref of measurement_batch hashrefs sorted by
measurement_time. Actual dip data are attached to cask hashrefs.

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
"cask", "cask_management", "gyle", "product", "product_order" or
"distributor".

The distinction between "cask" and "cask_management" is one of timing:
the latter refers to the casks expected prior to the festival, adding
any extra arrivals once the festival has started. The "cask" level
simply refers to actual casks which have arrived.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<BeerFestDB::Dumper>, L<BeerFestDB::Dumper::OODoc>, L<BeerFestDB::DipMunger>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

