#============================================================= -*-perl-*-
#
# t/debug.t
#
# Test the Debug plugin module.
#
# Written by Andy Wardley <abw@andywardley.com>
#
# Copyright (C) 2002 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test qw( :all );
use Template::Parser;
use Template::Directive;

my $DEBUG = grep(/-d/, @ARGV);
#$Template::Parser::DEBUG = $DEBUG;
$Template::Directive::Pretty = $DEBUG;
$Template::Test::PRESERVE = 1;

my $dir   = -d 't' ? 't/test' : 'test';

my $vars = {
    foo => 10,
    bar => 20,
    baz => {
	ping => 100,
	pong => 200,
    },
};

my $tt = Template->new( {
    DEBUG => 0,
    INCLUDE_PATH => "$dir/src:$dir/lib",
    DEBUG_FORMAT => "<!-- \$file line \$line : [% \$text %] -->",
} );

my $tt2 = Template->new( {
    DEBUG => 1,
    INCLUDE_PATH => "$dir/src:$dir/lib",
} );

my $ttd = Template->new( {
    DEBUG => 1,
    INCLUDE_PATH => "$dir/src:$dir/lib",
    DEBUG_FORMAT => "<!-- \$file line \$line : [% \$text %] -->",
} );

test_expect(\*DATA, [ default => $tt, debug => $ttd, debug2 => $tt2 ], $vars);
#$tt->process(\*DATA, $vars) || die $tt->error();
#print $tt->context->_dump();

__DATA__
-- test --
Hello World
foo: [% foo %]
-- expect --
Hello World
foo: 10

-- test --
-- use debug --
Hello World
foo: [% foo %]
-- expect --
Hello World
foo: <!-- input text line 2 : [% foo %] -->10

-- test --
-- use default --
Hello World
foo: [% foo %]
[% DEBUG on -%]
Debugging enabled
foo: [% foo %]
-- expect --
Hello World
foo: 10
Debugging enabled
foo: 10

-- test --
-- use debug --
[% DEBUG off %]
Hello World
foo: [% foo %]
[% DEBUG on -%]
Debugging enabled
foo: [% foo %]
-- expect --
<!-- input text line 1 : [% DEBUG off %] -->
Hello World
foo: 10
Debugging enabled
foo: <!-- input text line 6 : [% foo %] -->10

-- test --
foo: [% foo %]
hello [% "$baz.ping/$baz.pong" %] world
[% DEBUG off %]
bar: [% bar %][% DEBUG on %]
-- expect --
foo: <!-- input text line 1 : [% foo %] -->10
hello <!-- input text line 2 : [% "$baz.ping/$baz.pong" %] -->100/200 world
<!-- input text line 3 : [% DEBUG off %] -->
bar: 20



-- test --
-- use debug --
foo: [% foo %]
[% INCLUDE foo a=10 %]
[% DEBUG off -%]
foo: [% foo %]
[% INCLUDE foo a=20 %]
-- expect --
foo: <!-- input text line 1 : [% foo %] -->10
<!-- input text line 2 : [% INCLUDE foo a=10 %] -->This is the foo file, a is 10
<!-- input text line 3 : [% DEBUG off %] -->foo: 10
This is the foo file, a is 20


-- stop --



-- test --
-- use default --
[% DEBUG on -%]
[% DEBUG format '[ $file line $line ]' %]
[% foo %]
-- expect --
<!-- input text line 2 : [% DEBUG format '[ $file line $line ]' %] -->
[ input text line 3 ]10


-- test --
-- use default --
[% DEBUG on + format '[ $file line $line ]' -%]
[% foo %]
-- expect --
[ input text line 2 ]10

-- test --
[% DEBUG on;
   DEBUG format '$text at line $line of $file';
   DEBUG msg line='3.14' file='this file' text='hello world' 
%]
-- expect --
hello world at line 3.14 of this file

