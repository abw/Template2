#============================================================= -*-perl-*-
#
# t/parser.t
#
# Test the Template::Parser module.
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
use Template::Config;
use Template::Parser;
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 0;

my $p2 = Template::Parser->new({
    START_TAG => '\[\*',
    END_TAG   => '\*\]',
    PRE_CHOMP => 1,
    V1DOLLAR  => 1,
});

my $p3 = Template::Config->parser({
    TAG_STYLE  => 'html',
    POST_CHOMP => 1,
    INTERPOLATE => 1,
});

my $p4 = Template::Config->parser({
    CASE => 1,
});

my $tt = [
    tt1 => Template->new(),
    tt2 => Template->new(PARSER => $p2),
    tt3 => Template->new(PARSER => $p3),
    tt4 => Template->new(PARSER => $p4),
];

test_expect(\*DATA, $tt, &callsign());

__DATA__
#------------------------------------------------------------------------
# tt1
#------------------------------------------------------------------------
-- test --
start $a
[% BLOCK a %]
this is a
[% END %]
=[% INCLUDE a %]=
=[% include a %]=
end
-- expect --
start $a

=
this is a
=
=
this is a
=
end

#------------------------------------------------------------------------
# tt2
#------------------------------------------------------------------------
-- test --
-- use tt2 --
begin
[% this will be ignored %]
[* a *]
end
-- expect --
begin
[% this will be ignored %]alpha
end

-- test --
$b does nothing: 
[* c = 'b'; 'hello' *]
stuff: 
[* $c *]
-- expect --
$b does nothing: hello
stuff: b

#------------------------------------------------------------------------
# tt3
#------------------------------------------------------------------------
-- test --
-- use tt3 --
begin
[% this will be ignored %]
<!-- a -->
end

-- expect --
begin
[% this will be ignored %]
alphaend

-- test --
$b does something: 
<!-- c = 'b'; 'hello' -->
stuff: 
<!-- $c -->
end
-- expect --
bravo does something: 
hellostuff: 
bravoend


#------------------------------------------------------------------------
# tt4
#------------------------------------------------------------------------
-- test --
-- use tt4 --
start $a[% 'include' = 'hello world' %]
[% BLOCK a -%]
this is a
[%- END %]
=[% INCLUDE a %]=
=[% include %]=
end
-- expect --
start $a

=this is a=
=hello world=
end
