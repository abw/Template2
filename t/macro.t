#============================================================= -*-perl-*-
#
# t/macro.t
#
# Template script testing the MACRO directives.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Test;
$^W = 1;

my $config = {
    INCLUDE_PATH => -d 't' ? 't/test/src' : 'test/src',
    TRIM => 1,
};

test_expect(\*DATA, $config, &callsign);

__DATA__
-- test --
[% MACRO foo INCLUDE foo -%]
foo: [% foo %]
foo(b): [% foo(a = b) %]
-- expect --
foo: This is the foo file, a is alpha
foo(b): This is the foo file, a is bravo

-- test --
foo: [% foo %].
-- expect --
foo: .

-- test --
[% MACRO foo(a) INCLUDE foo -%]
foo: [% foo %]
foo(c): [% foo(c) %]
-- expect --
foo: This is the foo file, a is
foo(c): This is the foo file, a is charlie





