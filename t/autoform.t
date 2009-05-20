#============================================================= -*-perl-*-
#
# t/autoform.t
#
# Template script testing the autoformat plugin.
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
use warnings;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
use POSIX qw( localeconv );

$Template::Test::DEBUG = 0;
$Template::Test::PRESERVE = 1;

eval "use Text::Autoformat";

if ($@) {
    skip_all('Text::Autoformat module not installed');
}
if ($] >= 5.008) {
     skip_all("Text::Autoformat tests unreliable under $]");
}

# for testing known bug with locales that don't use '.' as a decimal 
# separator - see TODO file.
# POSIX::setlocale( &POSIX::LC_ALL, 'sv_SE' );

my $loc = localeconv;
my $dec = $loc->{ decimal_point };

my $vars = {
    decimal => $dec,
};

test_expect(\*DATA, { POST_CHOMP => 1 }, $vars);
 

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
-- test --
[% global.text = BLOCK %]
This is some text which
I would like to have formatted
and I should ensure that it continues
for a reasonable length
[% END %]
[% USE Autoformat(left => 3, right => 20) %]
[% Autoformat(global.text) %]
-- expect --
  This is some text
  which I would like
  to have formatted
  and I should
  ensure that it
  continues for a
  reasonable length

-- test --
[% USE autoformat(left=5) %]
[% autoformat(global.text, right=30) %]
-- expect --
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

-- test --
[% USE autoformat %]
[% autoformat(global.text, 'more text', right=50) %]
-- expect --
This is some text which I would like to have
formatted and I should ensure that it continues
for a reasonable length more text

-- test --
[% USE autoformat(left=10) %]
[% global.text | autoformat %]
-- expect --
         This is some text which I would like to have formatted and I
         should ensure that it continues for a reasonable length

-- test --
[% USE autoformat(left=5) %]
[% global.text | autoformat(right=30) %]
-- expect --
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

-- test --
[% USE autoformat %]
[% FILTER autoformat(right=>30, case => 'upper') -%]
This is some more text.  OK!  There's no need to shout!
> quoted stuff goes here
> more quoted stuff
> blah blah blah
[% END %]
-- expect --
THIS IS SOME MORE TEXT. OK!
THERE'S NO NEED TO SHOUT!
> quoted stuff goes here
> more quoted stuff
> blah blah blah

-- test --
[% USE autoformat %]
[% autoformat(global.text, ' of time.') %]
-- expect --
This is some text which I would like to have formatted and I should
ensure that it continues for a reasonable length of time.

-- test --
[% USE autoformat %]
[% autoformat(global.text, ' of time.', right=>30) %]
-- expect --
This is some text which I
would like to have formatted
and I should ensure that it
continues for a reasonable
length of time.

-- test --
[% USE autoformat %]
[% FILTER poetry = autoformat(left => 20, right => 40) %]
   Be not afeard.  The isle is full of noises, sounds and sweet 
   airs that give delight but hurt not.
[% END %]
[% FILTER poetry %]
   I cried to dream again.
[% END %]

-- expect --
                   Be not afeard. The
                   isle is full of
                   noises, sounds and
                   sweet airs that give
                   delight but hurt not.
                   I cried to dream
                   again.

-- test --
Item      Description          Cost
===================================
[% form = BLOCK %]
<<<<<<    [[[[[[[[[[[[[[[   >>>>.<<
[% END -%]
[% USE autoformat(form => form) %]
[% autoformat('foo', 'The Foo Item', 123.545) %]
[% autoformat('bar', 'The Bar Item', 456.789) %]
-- expect --
-- process --
Item      Description          Cost
===================================
foo       The Foo Item       123[% decimal %]55
bar       The Bar Item       456[% decimal %]79

-- test --
[% USE autoformat(form => '>>>.<<', numeric => 'AllPlaces') %]
[% autoformat(n) 
    FOREACH n = [ 123, 34.54, 99 ] +%]
[% autoformat(987, 654.32) %]
-- expect --
-- process --
123[% decimal %]00
 34[% decimal %]54
 99[% decimal %]00

987[% decimal %]00
654[% decimal %]32
