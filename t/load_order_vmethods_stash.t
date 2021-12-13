use strict;

use Test::More tests => 1;

require Template::VMethods;
require Template::Stash;
require Template;

my $ok = !!eval { Template->new({}); 1 };
my $err = $@;

ok($ok) or diag $err;
