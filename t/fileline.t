#============================================================= -*-perl-*-
#
# t/fileline.t
#
# Test the reporting of template file and line number in errors.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2003 Andy Wardley.  All Rights Reserved.
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
use Template::Parser;
use Template::Directive;
$^W = 1;

#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $dir = -d 't' ? 't/test/lib' : 'test/lib';

my $warning;
local $SIG{__WARN__} = sub {
    $warning = shift;
};

my $vars = {
    warning => sub { return $warning },
    file => sub {
        $warning =~ /at (.*?) line/;
        return $1;
    },
    line => sub {
        $warning =~ /line (\d*)/;
        return $1;
    },
    warn => sub {
        $warning =~ /(.*?) at /;
        return $1;
    },
};


test_expect(\*DATA, { INCLUDE_PATH => $dir }, $vars);

__DATA__
-- test --
[% place = 'World' -%]
Hello [% place %]
[% a = a + 1 -%]
file: [% file %]
line: [% line %]
warn: [% warn %]
-- expect --
-- process --
Hello World
file: input text
line: 3
warn: Argument "" isn't numeric in addition (+)

-- start --
-- test --
[% INCLUDE warning -%]
file: [% file %]
line: [% line %]
warn: [% warn %]
-- expect --
-- process --
Hello
World
file: test/lib/warning
line: 2
warn: Argument "" isn't numeric in addition (+)
