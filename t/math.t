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
