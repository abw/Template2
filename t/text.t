#============================================================= -*-perl-*-
#
# t/text.t
#
# Test general text blocks, ensuring all characters can be used.
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

my $tt = [
    basic  => Template->new(),
    interp => Template->new(INTERPOLATE => 1),
];

test_expect(\*DATA, $tt, callsign);

__DATA__
-- test --
This is a text block "hello" 'hello' 1/3 1\4 <html> </html>
$ @ { } @{ } ${ } # ~ ' ! % *foo
$a ${b} $c
-- expect --
This is a text block "hello" 'hello' 1/3 1\4 <html> </html>
$ @ { } @{ } ${ } # ~ ' ! % *foo
$a ${b} $c

-- test --
<table width=50%>&copy;
-- expect --
<table width=50%>&copy;

-- test --
[% foo = 'Hello World' -%]
start
[%
#
# [% foo %]
#
#
-%]
end
-- expect --
start
end

-- test --
pre
[%
# [% PROCESS foo %]
-%]
mid
[% BLOCK foo; "This is foo"; END %]
-- expect --
pre
mid

-- test --
-- use interp --
This is a text block "hello" 'hello' 1/3 1\4 <html> </html>
\$ @ { } @{ } \${ } # ~ ' ! % *foo
$a ${b} $c
-- expect --
This is a text block "hello" 'hello' 1/3 1\4 <html> </html>
$ @ { } @{ } ${ } # ~ ' ! % *foo
alpha bravo charlie

-- test --
<table width=50%>&copy;
-- expect --
<table width=50%>&copy;

-- test --
[% foo = 'Hello World' -%]
start
[%
#
# [% foo %]
#
#
-%]
end
-- expect --
start
end

-- test --
pre
[%
#
# [% PROCESS foo %]
#
-%]
mid
[% BLOCK foo; "This is foo"; END %]
-- expect --
pre
mid



