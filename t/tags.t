#============================================================= -*-perl-*-
#
# t/tags.t
#
# Template script testing TAGS parse-time directive to switch the
# tokens that mark start and end of directive tags.
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
use lib qw( ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $params = {
    'a'  => 'alpha',
    'b'  => 'bravo',
    'c'  => 'charlie',
    'd'  => 'delta',
    'e'  => 'echo',
};


test_expect(\*DATA, { INTERPOLATE => 1 }, $params);

__DATA__
[%a%] [% a %] [% a %]
-- expect --
alpha alpha alpha

-- test --
Redefining tags
[% TAGS (+ +) %]
[% a %]
[% b %]
(+ c +)
-- expect --
Redefining tags

[% a %]
[% b %]
charlie

-- test --
[% a %]
[% TAGS (+ +) %]
[% a %]
%% b %%
(+ c +)
(+ TAGS <* *> +)
(+ d +)
<* e *>
-- expect --
alpha

[% a %]
%% b %%
charlie

(+ d +)
echo

-- test --
[% TAGS default -%]
[% a %]
%% b %%
(+ c +)
-- expect --
alpha
%% b %%
(+ c +)

-- test --
[% TAGS metatext -%]
[% a %]
%% b %%
<* c *>
-- expect --
[% a %]
bravo
<* c *>

-- test --
[% TAGS ttmeta -%]
[% a %]
%% b %%
(+ c +)
-- expect --
alpha
bravo
(+ c +)

-- test --
[% TAGS html -%]
[% a %]
%% b %%
<!-- c -->
-- expect --
[% a %]
%% b %%
charlie

-- test --
[% TAGS asp -%]
[% a %]
%% b %%
<!-- c -->
<% d %>
<? e ?>
-- expect --
[% a %]
%% b %%
<!-- c -->
delta
<? e ?>

-- test --
[% TAGS php -%]
[% a %]
%% b %%
<!-- c -->
<% d %>
<? e ?>
-- expect --
[% a %]
%% b %%
<!-- c -->
<% d %>
echo




