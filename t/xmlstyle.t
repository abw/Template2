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

# $Template::Test::PRESERVE = 1;

test_expect(\*DATA);

__END__
-- test --
[% USE xmlstyle -%]
[% FILTER xmlstyle -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<foo>The foo</foo>
<bar>The bar</bar>

-- test --
[% USE xmlstyle foo = { element = 'bar' } -%]
[% FILTER xmlstyle -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<bar>The foo</bar>
<bar>The bar</bar>

-- test --
[% USE xmlstyle foo = { element = 'baz' } -%]
[% FILTER xmlstyle -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<baz>The foo</baz>
<bar>The bar</bar>

-- test --
[% USE xmlstyle -%]
[% FILTER xmlstyle foo = { element = 'wiz' } -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<wiz>The foo</wiz>
<bar>The bar</bar>

--  test --
[%    USE xmlstyle foo = { element = 'bar' } -%]
[% FILTER xmlstyle foo = { element = 'baz' } -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<baz>The foo</baz>
<bar>The bar</bar>

-- test --
[%    USE xmlstyle foo = { element = 'oof' } -%]
[% FILTER xmlstyle bar = { element = 'rab' } -%]
<foo>The foo</foo>
<bar>The bar</bar>
[%- END %]
-- expect --
<oof>The foo</oof>
<rab>The bar</rab>

--  test --
[%    USE xmlstyle -%]
[% FILTER xmlstyle foo = { attributes = { wiz = 'waz' } } -%]
<foo>The foo</foo>
[%- END %]
-- expect --
<foo wiz="waz">The foo</foo>

--  test --
[%    USE xmlstyle foo = { attributes = { wiz = 'waz' } }-%]
[% FILTER xmlstyle bar = { attributes = { biz = 'boz' } } -%]
<foo>The foo <bar>blam</bar></foo>
[%- END %]
-- expect --
<foo wiz="waz">The foo <bar biz="boz">blam</bar></foo>

--  test --
[% USE xmlstyle 
       list = {
	   element    = 'ul'
	   pre_start  = "<p>\n"
	   post_start = "\n<!-- list begins -->"
	   pre_end    = "<!-- list ends -->\n"
	   post_end   = "\n</p>"
	   attributes = { class = 'mylist' } 
       }
       item = {
	   element    = 'li'
	   post_start = '<small>'
	   pre_end    = '</small>'
	   post_end   = "\n<br/>"
	   attributes = { class = 'myitem' } 
       }
-%]
[% FILTER xmlstyle -%]
<list>
<item>The First Item</item>
<item>The Second Item</item>
<item>The Third Item</item>
</list>
[%- END %]
-- expect --
<p>
<ul class="mylist">
<!-- list begins -->
<li class="myitem"><small>The First Item</small></li>
<br/>
<li class="myitem"><small>The Second Item</small></li>
<br/>
<li class="myitem"><small>The Third Item</small></li>
<br/>
<!-- list ends -->
</ul>
</p>

