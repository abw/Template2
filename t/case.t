#============================================================= -*-perl-*-
#
# t/case.t
#
# Test the CASE sensitivity option.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

ok(1);

my $config = { 
    CASE => 1, 
    POST_CHOMP => 1,
};

test_expect(\*DATA, $config, callsign());

__DATA__
-- test --
[% include = a %]
[% for = b %]
i([% include %])
f([% for %])
-- expect --
i(alpha)
f(bravo)

-- test --
[% IF a AND b %]
good
[% ELSE %]
bad
[% END %]
-- expect --
good

-- test --
# 'and', 'or' and 'not' can ALWAYS be expressed in lower case, regardless
# of CASE sensitivity option.
[% IF a and b %]
good
[% ELSE %]
bad
[% END %]
-- expect --
good

-- test --
[% include = a %]
[% include %]
-- expect --
alpha






