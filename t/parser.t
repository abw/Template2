#============================================================= -*-perl-*-
#
# t/parser.t
#
# Test the parser, including quoting, interpolation flags, etc.
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
use lib qw( . ../lib );
use Template::Test;
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 0;

my $config = {
    INTERPOLATE => 1,
};

my $vars = {
    a => 'alpha',
    b => 'bravo',
    c => 'charlie',
};

test_expect(\*DATA, $config, $vars);

__DATA__
-- test --
[% a %] at $b @ [% c %]

-- expect --
alpha at bravo @ charlie




