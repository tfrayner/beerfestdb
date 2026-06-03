configure_requires 'ExtUtils::MakeMaker',                  '6.52';
configure_requires 'Module::CPANfile',                     '1.1';

requires 'Catalyst::Runtime',                              '5.90130';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Authentication',               '0.10023';
requires 'Catalyst::Plugin::Authorization::ACL',           '0.16';
requires 'Catalyst::Plugin::Authorization::Roles',         '0.09';
recommends 'Catalyst::Plugin::OpenIDConnect',              '0.13';
requires 'Catalyst::Plugin::CSRFToken';
requires 'Catalyst::Authentication::Store::DBIx::Class',   '0.1506';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';

requires 'Digest::SHA',                                    '6.04';
requires 'Crypt::SaltedHash',                              '0.09';
requires 'Bytes::Random::Secure';
requires 'MIME::Lite::TT::HTML';
requires 'Net::SMTP';
requires 'Config::YAML';
requires 'JSON::MaybeXS';
requires 'Cpanel::JSON::XS';
requires 'DBIx::Class';
requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'Readonly';
requires 'Text::CSV_XS';
requires 'Template';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'Number::Format';
requires 'LWP';
requires 'LWP::Protocol::https';
requires 'HTTP::Cookies';
requires 'Term::ReadLine';
requires 'Term::ReadKey';
requires 'String::Range::Expand';
recommends 'DBD::MariaDB';
requires 'YAML::XS';
requires 'OpenOffice::OODoc';
requires 'Exception::Class';
requires 'Try::Tiny::ByClass';
requires 'parent';

recommends 'IO::Socket::SSL'; # Required for secure SMTP connections, but not strictly necessary if using an unencrypted connection to localhost.
recommends 'Redis::Fast'; # Either Redis or Redis::Fast recommended for OIDC support in FastCGI environment

on 'test' => sub{
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::WWW::Mechanize::Catalyst';
    requires 'DBD::SQLite';
    requires 'File::Copy';
    recommends 'Test::Pod::Coverage';
    recommends 'Test::Pod';
}