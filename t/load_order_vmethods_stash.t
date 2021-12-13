use strict;

use Test2::V0;
use Test2::Plugin::NoWarnings;

plan tests => 1;

require Template::VMethods;
require Template::Stash;
require Template;

my $ok = !!eval { Template->new({}); 1 };
my $err = $@;

ok($ok) or diag $err;
