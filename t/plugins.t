#============================================================= -*-perl-*-
#
# t/plugins.t
#
# Test the Template::Plugins module.
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
use Cwd qw( abs_path );
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Plugins::DEBUG = 0;

my $dir = abs_path( -d 't' ? 't/test/plugin' : 'test/plugin' );
unshift(@INC, $dir);

my $tt1 = Template->new({      
    PLUGIN_BASE => 'MyPlugs',
});

require "MyPlugs/Bar.pm";
my $bar = MyPlugs::Bar->new(4);

my $tt2 = Template->new({      
    PLUGINS => {
	bar => 'MyPlugs::Bar',
	baz => 'MyPlugs::Foo',
	cgi => 'MyPlugs::Bar',
    },
});

my $tt3 = Template->new({
    LOAD_PERL => 1,
});

my $tt = [
    def => Template->new(),
    tt1 => $tt1,
    tt2 => $tt2,
    tt3 => $tt3,
];

test_expect(\*DATA, $tt, &callsign());

__END__
#------------------------------------------------------------------------
# basic plugin loads
#------------------------------------------------------------------------
-- test --
[% USE Table([2, 3, 5, 7, 11, 13], rows=2) -%]
[% Table.row(0).join(', ') %]
-- expect --
2, 5, 11

-- test --
[% USE table([17, 19, 23, 29, 31, 37], rows=2) -%]
[% table.row(0).join(', ') %]
-- expect --
17, 23, 31

-- test --
[% USE t = Table([41, 43, 47, 49, 53, 59], rows=2) -%]
[% t.row(0).join(', ') %]
-- expect --
41, 47, 53

-- test --
[% USE t = table([61, 67, 71, 73, 79, 83], rows=2) -%]
[% t.row(0).join(', ') %]
-- expect --
61, 71, 79

#------------------------------------------------------------------------
# load Foo plugin through custom PLUGIN_BASE
#------------------------------------------------------------------------
-- test --
-- use tt1 --
-- test --
[% USE t = table([89, 97, 101, 103, 107, 109], rows=2) -%]
[% t.row(0).join(', ') %]
-- expect --
89, 101, 107

-- test --
[% USE Foo(2) -%]
[% Foo.output %]
-- expect --
This is the Foo plugin, value is 2

-- test --
[% USE Bar(4) -%]
[% Bar.output %]
-- expect --
This is the Bar plugin, value is 4

#------------------------------------------------------------------------
# load Foo plugin through custom PLUGINS
#------------------------------------------------------------------------

-- test --
-- use tt2 --
[% USE t = table([113, 127, 131, 137, 139, 149], rows=2) -%]
[% t.row(0).join(', ') %]
-- expect --
113, 131, 139

-- test --
[% TRY -%]
[% USE Foo(8) -%]
[% Foo.output %]
[% CATCH -%]
ERROR: [% error.info %]
[% END %]
-- expect --
ERROR: Foo: plugin not found

-- test --
[% USE bar(16) -%]
[% bar.output %]
-- expect --
This is the Bar plugin, value is 16

-- test --
[% USE qux = baz(32) -%]
[% qux.output %]
-- expect --
This is the Foo plugin, value is 32

-- test --
[% USE wiz = cgi(64) -%]
[% wiz.output %]
-- expect --
This is the Bar plugin, value is 64

#------------------------------------------------------------------------
# LOAD_PERL
#------------------------------------------------------------------------

-- test --
-- use tt3 --
[% USE baz = MyPlugs.Baz(128) -%]
[% baz.output %]
-- expect --
This is the Baz module, value is 128
