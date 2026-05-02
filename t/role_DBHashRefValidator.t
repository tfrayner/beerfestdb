use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use TestFestivalDB qw(schema);

BEGIN { use_ok 'BeerFestDB::Role::DBHashRefValidator' }

# Minimal consumer implementing the required value_is_acceptable method.
{
    package TestDBValidator;
    use Moose;
    with 'BeerFestDB::Role::DBHashRefValidator';

    sub value_is_acceptable {
        my ( $self, $value ) = @_;
        return ( defined $value && $value ne q{} && $value !~ m/\A \?+ \z/xms );
    }
}

my $validator = TestDBValidator->new();
my $db        = schema();

# -----------------------------------------------------------------------
# resultset_required_columns
# -----------------------------------------------------------------------

my $company_rs = $db->resultset('Company');
my ( $required, $optional ) = $validator->resultset_required_columns( $company_rs );

ok( ref $required eq 'ARRAY', 'resultset_required_columns: required is an arrayref' );
ok( ref $optional eq 'ARRAY', 'resultset_required_columns: optional is an arrayref' );
ok( grep { $_ eq 'name' } @$required,
    'resultset_required_columns: name is a required column for Company' );

# -----------------------------------------------------------------------
# validate_against_resultset
# -----------------------------------------------------------------------

ok( $validator->validate_against_resultset(
        { name => 'Test Brewery', company_region_id => 5 },
        $company_rs ),
    'validate_against_resultset: valid attrs pass for Company' );

dies_ok {
    $validator->validate_against_resultset( {}, $company_rs )
} 'validate_against_resultset: missing required field dies';

dies_ok {
    $validator->validate_against_resultset(
        { name => 'Test', no_such_column => 'oops' },
        $company_rs )
} 'validate_against_resultset: unrecognised attribute dies';

# -----------------------------------------------------------------------
# resultset_missing_requirements
# -----------------------------------------------------------------------

my @missing = $validator->resultset_missing_requirements(
    { company_region_id => 5 },    # name is missing
    $company_rs );

ok( grep { $_ eq 'name' } @missing,
    'resultset_missing_requirements: identifies missing required column' );

my @none_missing = $validator->resultset_missing_requirements(
    { name => 'Acme', company_region_id => 1 },
    $company_rs );

is( scalar @none_missing, 0,
    'resultset_missing_requirements: no missing columns when all required fields present' );

# Placeholder values (strings of ?) should count as missing.
my @placeholder_missing = $validator->resultset_missing_requirements(
    { name => '???', company_region_id => 1 },
    $company_rs );

ok( grep { $_ eq 'name' } @placeholder_missing,
    'resultset_missing_requirements: placeholder value ??? treated as missing' );

done_testing();
