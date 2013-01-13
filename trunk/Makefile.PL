#!/usr/bin/env perl
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

use inc::Module::Install;

name 'BeerFestDB-Web';
all_from 'lib/BeerFestDB/Web.pm';

requires 'Catalyst::Runtime' => '5.7015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Authentication'               => '0.10007';
requires 'Catalyst::Plugin::Authorization::ACL'           => '0.08';    # NOT 0.09!
requires 'Catalyst::Plugin::Authorization::Roles'         => '0.05';
requires 'Catalyst::Authentication::Store::DBIx::Class'   => '0.104';
requires 'Digest::SHA1'                                   => '2.11';
requires 'Crypt::SaltedHash'                              => '0.06';
requires 'Catalyst::Engine::HTTP::Restarter';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::YAML';

requires 'Catalyst::View::JSON';
requires 'JSON::DWIW';
requires 'Catalyst::View::TT';
requires 'DBIx::Class';
requires 'Moose';
requires 'Readonly';
requires 'Text::CSV_XS';
requires 'Template';

requires 'LWP';
requires 'HTTP::Cookies';
requires 'Term::ReadLine';
requires 'Term::ReadKey';

recommends 'OpenOffice::OODoc';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
