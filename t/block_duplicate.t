use strict;
use warnings;

use Test::More tests => 1;

use Template;

my $warning_seen;
local $SIG{__WARN__} = sub {
    my @warnings = @_;
    if ($warnings[0] =~ /Block redefined: b1/) {
        ++$warning_seen;
    } else {
        die "Unexpected warning: ", @warnings;
    }
};

my $t = Template->new;
$t->process(\ << '__TEMPLATE__', {}, \ my $ignore_output);
[% BLOCK b1 %]first[% END %]
[% BLOCK b1 %]second[% END %]
__TEMPLATE__

is $warning_seen, 1, 'warning seen';
