#============================================================= -*-perl-*-
#
# t/xmlstyle.t
#
# Test the XML::Style plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( ./lib ../lib ../blib/arch );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

test_expect(\*DATA);

__END__
-- test --
[% USE xmlstyle foo = { element = 'bar' } -%]
[% FILTER xmlstyle -%]
<foo>The foo</foo>
[%- END %]
-- expect --
<bar>The foo</bar>

--  test --
[% USE xmlstyle foo = { element = 'bar' } -%]
[% FILTER xmlstyle foo = { element = 'baz' } -%]
<foo>The foo</foo>
[%- END %]
-- expect --
<baz>The foo</baz>

--  test --
[% USE xmlstyle -%]
[% FILTER xmlstyle foo = { attributes = { wiz = 'waz' } } -%]
<foo>The foo</foo>
[%- END %]
-- expect --
<foo wiz="waz">The foo</foo>

--  test --
[% USE xmlstyle foo = { attributes = { wiz = 'waz' } }-%]
[% FILTER xmlstyle bar = { attributes = { biz = 'boz' } } -%]
<foo>The foo <bar>blam</bar></foo>
[%- END %]
-- expect --
<foo wiz="waz">The foo <bar biz="boz">blam</bar></foo>


