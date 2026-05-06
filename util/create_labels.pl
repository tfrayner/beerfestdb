#!/usr/bin/env perl
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

use strict;
use warnings;

binmode(STDOUT, ":utf8");

# ---------------------------------------------------------------------------
package LabelMaker;
use Moose;
use namespace::autoclean;

use Template;
use Carp;

# The text to print on every label.
has 'label_text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# Total number of labels to generate.
has 'count' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has 'cols' => (
    is      => 'ro',
    isa     => 'Int',
    default => 3,
);

has 'rows' => (
    is      => 'ro',
    isa     => 'Int',
    default => 7,
);

# Page margin dimensions (mm).
has 'left_page_margin'   => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_page_margin()  } );
has 'right_page_margin'  => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_page_margin()  } );
has 'top_page_margin'    => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_page_margin()  } );
has 'bottom_page_margin' => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_page_margin()  } );

# Inter-label gap dimensions (mm).
has 'inter_label_col' => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_inter_col() } );
has 'inter_label_row' => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_inter_row() } );

# Label border / padding dimensions (mm).
has 'left_label_border'   => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_label_border() } );
has 'right_label_border'  => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_label_border() } );
has 'top_label_border'    => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_label_border() } );
has 'bottom_label_border' => ( is => 'ro', isa => 'Num', lazy => 1, default => sub { $_[0]->_default_label_border() } );

# Defaults derived from the cols/rows combination, matching the
# values used in the existing cask label templates (3x7 on A4).
my %DEFAULTS = (
    # cols => [ page_margin, inter_col, inter_row, label_border ]
    3 => [ 7,  2, 0, 5 ],
    4 => [ 6,  2, 0, 4 ],
    5 => [ 5,  1, 0, 3 ],
);
my @FALLBACK_DEFAULTS = ( 7, 2, 0, 5 );

sub _defaults {
    my ( $self ) = @_;
    return $DEFAULTS{ $self->cols() } // \@FALLBACK_DEFAULTS;
}

sub _default_page_margin  { $_[0]->_defaults()->[0] }
sub _default_inter_col    { $_[0]->_defaults()->[1] }
sub _default_inter_row    { $_[0]->_defaults()->[2] }
sub _default_label_border { $_[0]->_defaults()->[3] }

sub _latexify {
    my ( $self, $text ) = @_;
    # Escape the most common LaTeX special characters.
    $text =~ s/\\/\\textbackslash{}/g;
    $text =~ s/([&%\$#_\{\}])/\\$1/g;
    $text =~ s/\^/\\textasciicircum{}/g;
    $text =~ s/~/\\textasciitilde{}/g;
    return $text;
}

sub generate {
    my ( $self, $template_text ) = @_;

    my $tt = Template->new({ ABSOLUTE => 1 })
        or croak("Cannot create Template object: " . Template->error());

    my %vars = (
        label_text          => $self->_latexify( $self->label_text() ),
        count               => $self->count(),
        cols                => $self->cols(),
        rows                => $self->rows(),
        left_page_margin    => $self->left_page_margin(),
        right_page_margin   => $self->right_page_margin(),
        top_page_margin     => $self->top_page_margin(),
        bottom_page_margin  => $self->bottom_page_margin(),
        inter_label_col     => $self->inter_label_col(),
        inter_label_row     => $self->inter_label_row(),
        left_label_border   => $self->left_label_border(),
        right_label_border  => $self->right_label_border(),
        top_label_border    => $self->top_label_border(),
        bottom_label_border => $self->bottom_label_border(),
    );

    my $output = q{};
    $tt->process( \$template_text, \%vars, \$output )
        or croak("Template processing failed: " . $tt->error());

    return $output;
}

__PACKAGE__->meta->make_immutable;

# ---------------------------------------------------------------------------
package main;

use Getopt::Long qw(:config bundling);
use Pod::Usage;

sub parse_args {

    my %opt = ();
    GetOptions(
        \%opt,
        'count|n=i',
        'cols|c=i',
        'rows|r=i',
        'left-page-margin=f',
        'right-page-margin=f',
        'top-page-margin=f',
        'bottom-page-margin=f',
        'page-margin=f',
        'inter-col=f',
        'inter-row=f',
        'left-label-border=f',
        'right-label-border=f',
        'top-label-border=f',
        'bottom-label-border=f',
        'label-border=f',
        'template|t=s',
        'help|h',
    ) or pod2usage( -exitval => 1, -verbose => 0 );

    pod2usage( -exitval => 0, -verbose => 1 ) if $opt{help};

    my $text = shift @ARGV
        or pod2usage( -message => "Error: label text argument is required.\n",
                      -exitval => 1, -verbose => 0 );

    # Convenience shortcuts: --page-margin sets all four page margins;
    # --label-border sets all four label borders.
    if ( defined $opt{'page-margin'} ) {
        for my $side (qw(left right top bottom)) {
            $opt{"$side-page-margin"} //= $opt{'page-margin'};
        }
    }
    if ( defined $opt{'label-border'} ) {
        for my $side (qw(left right top bottom)) {
            $opt{"$side-label-border"} //= $opt{'label-border'};
        }
    }

    my $template_text;
    if ( my $tfile = $opt{template} ) {
        open( my $fh, '<', $tfile )
            or die("Cannot open template file '$tfile': $!\n");
        $template_text = do { local $/; <$fh> };
    }

    return( $text, \%opt, $template_text );
}

my ( $label_text, $opt, $template_text ) = parse_args();

# Read the __DATA__ template unless the user supplied an external one.
unless ( defined $template_text ) {
    $template_text = do { local $/; <DATA> };
}

my %args = ( label_text => $label_text );
$args{count} = $opt->{count}               if defined $opt->{count};
$args{cols}  = $opt->{cols}                if defined $opt->{cols};
$args{rows}  = $opt->{rows}                if defined $opt->{rows};
$args{left_page_margin}   = $opt->{'left-page-margin'}   if defined $opt->{'left-page-margin'};
$args{right_page_margin}  = $opt->{'right-page-margin'}  if defined $opt->{'right-page-margin'};
$args{top_page_margin}    = $opt->{'top-page-margin'}    if defined $opt->{'top-page-margin'};
$args{bottom_page_margin} = $opt->{'bottom-page-margin'} if defined $opt->{'bottom-page-margin'};
$args{inter_label_col}    = $opt->{'inter-col'}          if defined $opt->{'inter-col'};
$args{inter_label_row}    = $opt->{'inter-row'}          if defined $opt->{'inter-row'};
$args{left_label_border}   = $opt->{'left-label-border'}   if defined $opt->{'left-label-border'};
$args{right_label_border}  = $opt->{'right-label-border'}  if defined $opt->{'right-label-border'};
$args{top_label_border}    = $opt->{'top-label-border'}    if defined $opt->{'top-label-border'};
$args{bottom_label_border} = $opt->{'bottom-label-border'} if defined $opt->{'bottom-label-border'};

my $maker  = LabelMaker->new(%args);
my $output = $maker->generate($template_text);
print $output;

=head1 NAME

create_labels.pl - Generate a LaTeX label sheet from a short text string

=head1 SYNOPSIS

 create_labels.pl [options] "label text"

=head1 DESCRIPTION

Accepts a short text string and writes a LaTeX document (using the
C<labels> package) to STDOUT. The document can be compiled with
C<pdflatex> to produce a printable sheet of identical labels.

Redirect STDOUT to a C<.tex> file and then compile:

 create_labels.pl "TestBeer" > labels.tex
 pdflatex labels.tex

=head1 OPTIONS

=head2 -n, --count I<N>

Number of labels to generate.  Defaults to 1.

=head2 -c, --cols I<N>

Number of label columns per page.  Defaults to 3.  Sensible page-margin
and border defaults are provided for 3-, 4-, and 5-column layouts.

=head2 -r, --rows I<N>

Number of label rows per page.  Defaults to 7.

=head2 --page-margin I<mm>

Set all four page margins (in mm) simultaneously.

=head2 --left-page-margin, --right-page-margin, --top-page-margin, --bottom-page-margin I<mm>

Set individual page margins (in mm).  Override C<--page-margin>.

=head2 --inter-col I<mm>

Gap between label columns (mm).

=head2 --inter-row I<mm>

Gap between label rows (mm).

=head2 --label-border I<mm>

Set all four label borders (internal padding, in mm) simultaneously.

=head2 --left-label-border, --right-label-border, --top-label-border, --bottom-label-border I<mm>

Set individual label borders.  Override C<--label-border>.

=head2 -t, --template I<file>

Path to an alternate Template Toolkit template file.  The same
variables are available as in the built-in template (see C<__DATA__>).

=head2 -h, --help

Show this help message and exit.

=head1 AUTHOR

Tim F. Rayner, E<lt>tfrayner@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=head1 BUGS

Probably.

=cut

#
# What follows under __DATA__ is the LaTeX output template.
# Variables available:
#   label_text          - the (LaTeX-escaped) label text
#   count               - number of labels to emit
#   cols / rows         - grid dimensions
#   left/right/top/bottom_page_margin  - page margins in mm
#   inter_label_col / inter_label_row  - inter-label gaps in mm
#   left/right/top/bottom_label_border - label padding in mm
#

__DATA__
\documentclass[a4paper,12pt]{article}
\usepackage[newdimens]{labels}
\usepackage[T1]{fontenc}
\usepackage{graphicx}

\LabelCols=[% cols %]
\LabelRows=[% rows %]
\LabelInfotrue

\LeftPageMargin=[% left_page_margin %]mm
\RightPageMargin=[% right_page_margin %]mm
\TopPageMargin=[% top_page_margin %]mm
\BottomPageMargin=[% bottom_page_margin %]mm

\InterLabelColumn=[% inter_label_col %]mm
\InterLabelRow=[% inter_label_row %]mm

\LeftLabelBorder=[% left_label_border %]mm
\RightLabelBorder=[% right_label_border %]mm
\TopLabelBorder=[% top_label_border %]mm
\BottomLabelBorder=[% bottom_label_border %]mm

\renewcommand\familydefault{\sfdefault}

\begin{document}

\begin{labels}
[% FOREACH i = [ 1 .. count ] %]
\resizebox{\linewidth}{!}{\textbf{[% label_text %]}}
[% END %]
\end{labels}

\end{document}
