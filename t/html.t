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

my $html = -d 'templates' ? 'templates/html' : '../templates/html';
die "cannot grok templates/html directory\n" unless $html;

my $h = Template::Plugin::HTML->new('foo');
ok( $h );

my $cfg = {
    INCLUDE_PATH => $html,
};

test_expect(\*DATA, $cfg); 

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
[% FILTER html(entity = 1) -%]
< &amp; >
[%- END %]
-- expect --
&lt; &amp; &gt;
