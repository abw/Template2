#============================================================= -*-perl-*-
#
# t/while.t
#
# Test the WHILE directive
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
use Template::Parser;
use Template::Directive;
$^W = 1;

$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

# set low limit on WHILE's maximum iteration count
$Template::Directive::WHILE_MAX = 100;

my $config = {
    INTERPOLATE => 1, 
    POST_CHOMP  => 1,
};

my @list = ( 'x-ray', 'yankee', 'zulu', );
my @pending;
my $replace  = {
    'a'     => 'alpha',
    'b'     => 'bravo',
    'c'     => 'charlie',
    'd'     => 'delta',
    'dec'   => sub { --$_[0] },
    'inc'   => sub { ++$_[0] },
    'reset' => sub { @pending = @list; "Reset list\n" },
    'next'  => sub { shift @pending },
    'true'  => 1,
};

test_expect(\*DATA, $config, $replace);

__DATA__
before
[% WHILE bollocks %]
do nothing
[% END %]
after
-- expect --
before
after

-- test --
Commence countdown...
[% a = 10 %]
[% WHILE a %]
[% a %]..[% a = dec(a) %]
[% END +%]
The end
-- expect --
Commence countdown...
10..9..8..7..6..5..4..3..2..1..
The end

-- test --
[% reset %]
[% WHILE (item = next) %]
item: [% item +%]
[% END %]
-- expect --
Reset list
item: x-ray
item: yankee
item: zulu

-- test --
[% reset %]
[% WHILE (item = next) %]
item: [% item +%]
[% BREAK IF item == 'yankee' %]
[% END %]
Finis
-- expect --
Reset list
item: x-ray
item: yankee
Finis

-- test --
[% reset %]
[% "* $item\n" WHILE (item = next) %]
-- expect --
Reset list
* x-ray
* yankee
* zulu

-- test --
[% TRY %]
[% WHILE true %].[% END %]
[% CATCH +%]
error: [% error.info %]
[% END %]
-- expect --
...................................................................................................
error: WHILE loop terminated (> 100 iterations)


-- test --
[% reset %]
[% WHILE (item = next) %]
[% NEXT IF item == 'yankee' -%]
* [% item +%]
[% END %]
-- expect --
Reset list
* x-ray
* zulu
