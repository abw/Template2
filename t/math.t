#============================================================= -*-perl-*-
#
# t/math.t
#
# Test the Math plugin module.
#
# Written by Andy Wardley <abw@kfs.org> and ...
#
# Copyright (C) 2002 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test qw( :all );
$^W = 1;

test_expect(\*DATA);

__DATA__
-- test --
[% USE Math; Math.sqrt(9) %]
-- expect --
3

-- test --
[% USE Math; Math.abs(-1) %]
-- expect --
1

-- test --
[% USE Math; Math.atan2(42, 42) %]
-- expect --
0.785398163397448

-- test --
[% USE Math; Math.cos(2) %]
-- expect --
-0.416146836547142

-- test --
[% USE Math; Math.exp(6) %]
-- expect --
403.428793492735

-- test --
[% USE Math; Math.hex(42) %]
-- expect --
66

-- test --
[% USE Math; Math.int(9.9) %]
-- expect --
9

-- test --
[% USE Math; Math.log(42) %]
-- expect --
3.73766961828337

-- test --
[% USE Math; Math.oct(72) %]
-- expect --
58

-- test --
[% USE Math; Math.sin(0.304) %]
-- expect --
0.299339178269093



