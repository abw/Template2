#============================================================= -*-perl-*-
#
# t/stash.t
#
# Template script testing (some elements of) the Template::Stash
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
use Template::Constants qw( :status );
use Template;
use Template::Stash;
use Template::Config;
use Template::Test;
$^W = 1;

my $DEBUG = grep(/-d/, @ARGV);
#$Template::Parser::DEBUG     = $DEBUG;
#$Template::Directive::PRETTY = $DEBUG;

$Template::Config::STASH = 'Template::Stash';

my $count = 20;
my $data = {
    foo => 10,
    bar => {
	baz => 20,
    },
    baz => sub {
	return {
	    boz => ($count += 10),
	    biz => (shift || '<undef>'),
	};
    },
    obj => bless {
	name => 'an object',
    }, 'AnObject',
};

my $stash = Template::Stash->new($data);

match( $stash->get('foo'), 10 );
match( $stash->get([ 'bar', 0, 'baz', 0 ]), 20 );
match( $stash->get('bar.baz'), 20 );
match( $stash->get('bar(10).baz'), 20 );
match( $stash->get('baz.boz'), 30 );
match( $stash->get('baz.boz'), 40 );
match( $stash->get('baz.biz'), '<undef>' );
match( $stash->get('baz(50).biz'), '<undef>' );   # args are ignored

$stash->set( 'bar.buz' => 100 );
match( $stash->get('bar.buz'), 100 );

my $ttlist = [
    'default' => Template->new(),
    'warn'    => Template->new(DEBUG => 1, DEBUG_FORMAT => ''),
];

test_expect(\*DATA, $ttlist, $data);

__DATA__
-- test --
a: [% a %]
-- expect --
a: 

-- test --
-- use warn --
[% TRY; a; CATCH; "ERROR: $error"; END %]
-- expect --
ERROR: undef error - a is undefined

-- test --
-- use default --
[% myitem = 'foo' -%]
1: [% myitem %]
2: [% myitem.item %]
3: [% myitem.item.item %]
-- expect --
1: foo
2: foo
3: foo

-- test --
[% myitem = 'foo' -%]
[% "* $item\n" FOREACH item = myitem -%]
[% "+ $item\n" FOREACH item = myitem.list %]
-- expect --
* foo
+ foo

-- test --
[% myitem = 'foo' -%]
[% myitem.hash.value %]
-- expect --
foo

-- test --
[% myitem = 'foo'
   mylist = [ 'one', myitem, 'three' ]
   global.mylist = mylist
-%]
[% mylist.item %]
0: [% mylist.item(0) %]
1: [% mylist.item(1) %]
2: [% mylist.item(2) %]
-- expect --
one
0: one
1: foo
2: three

-- test --
[% "* $item\n" FOREACH item = global.mylist -%]
[% "+ $item\n" FOREACH item = global.mylist.list -%]
-- expect --
* one
* foo
* three
+ one
+ foo
+ three

-- test --
[% "* $item.key => $item.value\n" FOREACH item = global.mylist.hash -%]
-- expect --
* 0 => one
* 1 => foo
* 2 => three

-- test --
[% myhash = { msg => 'Hello World', things => global.mylist, a => 'alpha' };
   global.myhash = myhash 
-%]
* [% myhash.item('msg') %]
-- expect --
* Hello World

-- test --
[% "* $item.key => $item.value.item\n" 
    FOREACH item = global.myhash.list.sort('key') -%]
-- expect --
* a => alpha
* msg => Hello World
* things => one

-- test --
[% items = [ 'foo', 'bar', 'baz' ];
   take  = [ 0, 2 ];
   slice = items.$take;
   slice.join(', ');
%]
-- expect --
foo, baz

-- test --
[% items = {
    foo = 'one',
    bar = 'two',
    baz = 'three'
   }
   take  = [ 'foo', 'baz' ];
   slice = items.$take;
   slice.join(', ');
%]
-- expect --
one, three

-- test --
[% items = {
    foo = 'one',
    bar = 'two',
    baz = 'three'
   }
   keys = items.keys.sort;
   items.${keys}.join(', ');
%]
-- expect --
two, three, one


-- test --
[% obj.name %]
-- expect --
an object

-- test --
[% obj.name.list.first %]
-- expect --
an object

-- test --
[% obj.list.first.name %]
-- expect --
an object

-- test --
=[% size %]=
-- expect --
==
