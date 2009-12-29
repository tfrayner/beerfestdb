# $Id$
#
# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'BeerFestDB-Web';
all_from 'lib/BeerFestDB/Web.pm';

requires 'Catalyst::Runtime' => '5.7015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::YAML';

requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'DBIx::Class';
requires 'Moose';
requires 'Readonly';
requires 'Text::CSV_XS';
requires 'Template';

recommends 'OpenOffice::OODoc';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
