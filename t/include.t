#============================================================= -*-perl-*-
#
# t/include.t
#
# Template script testing the INCLUDE directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;
$Template::Context::DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my $params = { 
    'a' => $a,
    'b' => $b,
    'c' => {
	'd' => $d,
	'e' => $e,
	'f' => {
	    'g' => $g,
	    'h' => $h,
	},
    },
    'r'    => $r,
    's'	   => $s,
    't'    => $t,
};

my $tproc = Template->new({ 
    INTERPOLATE => 1,
    CACHE_DIR   => '/tmp/tt',
    INCLUDE_PATH => [ qw( t/test/src test/src ) ],
    RESET_BLOCKS => 0,
});
test_expect(\*DATA, $tproc, $params);

__DATA__
[% a %]
[% BLOCK first_block -%]
this is my first block, a is set to '[% a %]'
[%- END -%]
[% BLOCK second_block; DEFAULT b = 99 m = 98 -%]
this is my second block, a is initially set to '[% a %]' and 
then set to [% a = s %]'[% a %]'  b is $b  m is $m
[%- END -%]
[% b %]
-- expect --
alpha
bravo

-- test --
[% INCLUDE first_block %]
-- expect --
this is my first block, a is set to 'alpha'

-- test --
[% INCLUDE first_block a = 'abstract' %]
[% a %]
-- expect --
this is my first block, a is set to 'abstract'
alpha

-- test --
[% INCLUDE 'first_block' a = t %]
[% a %]
-- expect --
this is my first block, a is set to 'tango'
alpha

-- test --
[% INCLUDE 'second_block' %]
-- expect --
this is my second block, a is initially set to 'alpha' and 
then set to 'sierra'  b is bravo  m is 98

-- test --
[% INCLUDE second_block a = r, b = c.f.g, m = 97 %]
[% a %]
-- expect --
this is my second block, a is initially set to 'romeo' and 
then set to 'sierra'  b is golf  m is 97
alpha

-- test --
FOO: [% INCLUDE foo -%]
FOO: [% INCLUDE foo a = b -%]
-- expect --
FOO: This is foo  a is alpha
FOO: This is foo  a is bravo

-- test --
GOLF: [% INCLUDE $c.f.g %]
GOLF: [% INCLUDE $c.f.g  g = c.f.h %]
[% DEFAULT g = "a new $c.f.g" -%]
[% g %]
-- expect --
GOLF: This is the golf file, g is golf
GOLF: This is the golf file, g is hotel
a new golf

-- test --
BAZ: [% INCLUDE bar/baz %]
BAZ: [% INCLUDE bar/baz word='wizzle' %]
BAZ: [% INCLUDE "bar/baz" %]
-- expect --
BAZ: This is file baz
The word is 'qux'
BAZ: This is file baz
The word is 'wizzle'
BAZ: This is file baz
The word is 'qux'

-- test --
BAZ: [% INCLUDE bar/baz.txt %]
BAZ: [% INCLUDE bar/baz.txt time = 'nigh' %]
-- expect --
BAZ: This is file baz
The word is 'qux'
The time is now
BAZ: This is file baz
The word is 'qux'
The time is nigh

-- test --
[% BLOCK bamboozle -%]
This is bamboozle
[%- END -%]
Block defined...
[% blockname = 'bamboozle' -%]
[% INCLUDE $blockname %]
End
-- expect --
Block defined...
This is bamboozle
End
