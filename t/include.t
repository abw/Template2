#============================================================= -*-perl-*-
#
# t/include.t
#
# Template script testing the INCLUDE and PROCESS directives.
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

#$Template::Test::DEBUG = 0;
#$Template::Context::DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my $replace = { 
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

# script may be being run in distribution root or 't' directory
my $dir   = -d 't' ? 't/test' : 'test';
my $tproc = Template->new({ 
    INTERPOLATE  => 1,
    INCLUDE_PATH => "$dir/src:$dir/lib",
    TRIM         => 1,
    AUTO_RESET   => 0,
});

my $tt_reset = Template->new({ 
    INTERPOLATE  => 1,
    INCLUDE_PATH => "$dir/src:$dir/lib",
    TRIM         => 1,
});

test_expect(\*DATA, [ default => $tproc, reset => $tt_reset ], $replace);

__DATA__
-- test --
[% a %]
[% PROCESS incblock -%]
[% b %]
[% INCLUDE first_block %]
-- expect --
alpha
bravo
this is my first block, a is set to 'alpha'

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
FOO: [% INCLUDE foo +%]
FOO: [% INCLUDE foo a = b -%]
-- expect --
FOO: This is the foo file, a is alpha
FOO: This is the foo file, a is bravo

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


# test that BLOCK definitions get AUTO_RESET (i.e. cleared) by default
-- test --
-- use reset --
[% a %]
[% PROCESS incblock -%]
[% INCLUDE first_block %]
[% INCLUDE second_block %]
[% b %]
-- expect --
alpha
this is my first block, a is set to 'alpha'
this is my second block, a is initially set to 'alpha' and 
then set to 'sierra'  b is bravo  m is 98
bravo

-- test --
[% TRY %]
[% INCLUDE first_block %]
[% CATCH file %]
ERROR: [% error.info %]
[% END %]
-- expect --
ERROR: first_block: not found
