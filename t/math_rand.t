use strict;
use Test::More;
use Template;

plan tests => 1;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };
my $t = Template->new;
my $out;
$t->process(\<<EOF, {}, \$out) or die $t->error;
[% USE Math -%]
rand  with arg:    [% Math.rand(1000000) %]
rand  without arg: [% Math.rand %]
srand with arg:    [% Math.srand(1000000) %]
srand without arg: [% Math.srand %]
EOF
#diag $out;
is_deeply \@warnings, [], 'No warnings when calling rand/srand without arg';
