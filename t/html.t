#============================================================= -*-perl-*-
#
# t/html.t
#
# Tests the 'HTML' plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Template::Plugin::HTML;
$^W = 1;

$Template::Test::DEBUG = 0;
$Template::Test::PRESERVE = 1;

#------------------------------------------------------------------------
# behaviour of html filter depends on these being available
#------------------------------------------------------------------------

use constant HAS_HTML_Entities => eval { require HTML::Entities };
use constant HAS_Apache_Util   => eval { require Apache::Util;
				         Apache::Utils::escape_html(''); };


my $html = -d 'templates' ? 'templates/html' : '../templates/html';
die "cannot grok templates/html directory\n" unless $html;

my $h = Template::Plugin::HTML->new('foo');
ok( $h );

my $cfg = {
    INCLUDE_PATH => $html,
};

my $vars = {
    entities => HAS_HTML_Entities || HAS_Apache_Util || 0,
};

test_expect(\*DATA, $cfg, $vars); 

__DATA__
-- test --
[% USE HTML -%]
OK
-- expect --
OK

-- test --
[% FILTER html -%]
< &amp; >
[%- END %]
-- expect --
&lt; &amp;amp; &gt;

-- test --
[% TRY; 
      "Léon Brocard" | html_entity;
   CATCH;
     error;
   END
%]
-- expect --
-- process --
[%  IF entities -%]
L&eacute;on Brocard
[%- ELSE -%]
html_all error - cannot locate Apache::Util or HTML::Entities
[%- END %]

-- test --
[% USE html; html.url('my file.html') -%]
-- expect --
my%20file.html

-- test --
[% USE HTML -%]
[% HTML.escape("if (a < b && c > d) ...") %]
-- expect --
if (a &lt; b &amp;&amp; c &gt; d) ...

-- test --
[% USE HTML(sorted=1) -%]
[% HTML.element(table => { border => 1, cellpadding => 2 }) %]
-- expect --
<table border="1" cellpadding="2">

-- test --
[% USE HTML -%]
[% HTML.attributes(border => 1, cellpadding => 2).split.sort.join %]
-- expect --
border="1" cellpadding="2"

-- stop --
# These are tests for the now defunct 'entity' option.
# At some point this functionality should return elsewhere
# so we'll keep the tests lying around in case we need them
# again later.

-- test --
[% FILTER html(entity = 1) -%]
< &amp; >
[%- END %]
-- expect --
&lt; &amp; &gt;

-- test --
[% FILTER html(entity = 1) -%]
<foo> &lt;bar> <baz&gt; &lt;boz&gt;
[%- END %]
-- expect --
&lt;foo&gt; &lt;bar&gt; &lt;baz&gt; &lt;boz&gt;

