#============================================================= -*-perl-*-
#
# t/anycase.t
#
# Test the ANYCASE option.  This allows directive keywords to be specified
# in lower case.  The problem is that it would usually preclude the use of
# variables of the same name, or even hash keys matching directive keywords.
#
# Here's a simplified version of a real-life example:
#
#  [%
#     page = { wrapper = 'html '};
#     wrap = page.wrapper;
#     "some content" WRAPPER $wrap
#  %]
#
# I've added a couple of custom rules in the tokeniser to assume keywords
# aren't actually keywords if they follow a dot (e.g. page.wrapper) or
# precede an equals sign (e.g. { wrapper = 'html' }).
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2020 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

ok(1);

my $tt_vanilla = Template->new;
my $tt_anycase = Template->new({
    ANYCASE   => 1,
    TAG_STYLE => 'outline',
});

my $engines = [
    default => $tt_vanilla,
    anycase => $tt_anycase,
];


test_expect(\*DATA, $engines, callsign);

__DATA__
-- test --
-- name ANYCASE --
-- use anycase --
%% page = { wrapper = 'html', include = 'header', next = 'about.html' }
wrapper: [% page.wrapper %]
include: [% page.include %]
   next: [% page.next %]
[% BLOCK html %]<html>[% content %]</html>[% END -%]
%% wrapper $page.wrapper
Hello World!
%%- end
%% w = page.wrapper
%% wrapper $w
Much cool!
%%- end
-- expect --
wrapper: html
include: header
   next: about.html
<html>Hello World!</html><html>Much cool!</html>

-- test --
-- name template name is a keyword --
%% block view
This is the view
%% end
view: [% include view %]
-- expect --
view: This is the view

-- test --
-- name different kinds of include --
%% block include
This is the included template
%% end
%% include = include include
inc: [% GET include %]
-- expect --
inc: This is the included template
