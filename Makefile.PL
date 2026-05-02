#!/usr/bin/env perl
#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2026 Tim F. Rayner
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
use ExtUtils::MakeMaker;
use Module::CPANfile;

my $prereqs = Module::CPANfile->load('cpanfile')
    ->prereqs->merged_requirements(['runtime'], ['requires'])
    ->as_string_hash;

WriteMakefile(
    NAME          => 'BeerFestDB::Web',
    AUTHOR        => 'Tim F. Rayner',
    VERSION_FROM  => 'lib/BeerFestDB/Web.pm',
    ABSTRACT      => 'Catalyst based application',
    EXE_FILES     => [ glob('script/*.pl'), glob('util/*.pl') ],
    PREREQ_PM     => $prereqs,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Module::CPANfile'    => '1.1004',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tfrayner/beerfestdb.git',
                web  => 'https://github.com/tfrayner/beerfestdb',
            },
        },
    },
);
