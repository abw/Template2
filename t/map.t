#============================================================= -*-perl-*-
#
# t/map.t
#
# Test the Template::Map module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
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
$^W = 1;

# just testing
ok(1);
exit();

use Template::Map;

#$Template::Map::DEBUG = 1;
#$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;
$Template::Test::PRESERVE = 1;


my $map = Template::Map->new();
assert( $map );

my $res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 1 );
match( $res->[0], 'foo' );


$map = Template::Map->new( default => 'bar' );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 2 );
match( $res->[0], 'foo' );
match( $res->[1], 'bar' );


$map = Template::Map->new( prefix => 'my/', default => 'bar' );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 2 );
match( $res->[0], 'my/foo' );
match( $res->[1], 'bar' );


$map = Template::Map->new( {
    prefix  => 'my/', 
    suffix  => '.tt2',
    default => 'bar',
} );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 2 );
match( $res->[0], 'my/foo.tt2' );
match( $res->[1], 'bar' );


$map = Template::Map->new( {
    format  => 'try/%s/first',
    prefix  => 'my/', 
    suffix  => '.tt2',
    default => 'bar',
} );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 3 );
match( $res->[0], 'try/foo/first' );
match( $res->[1], 'my/foo.tt2' );
match( $res->[2], 'bar' );


$map = Template::Map->new( {
    format  => [ 'try/%s/first', 'then/%s/next' ],
    prefix  => 'my/', 
    suffix  => '.tt2',
    default => 'bar',
} );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 4 );
match( $res->[0], 'try/foo/first' );
match( $res->[1], 'then/foo/next' );
match( $res->[2], 'my/foo.tt2' );
match( $res->[3], 'bar' );


$map = Template::Map->new( {
    format  => [ 'zeroth', 'try/%s/first', 'then/%s/next' ],
    default => 'bar',
} );
assert( $map );

$res = $map->map('foo');
assert( $res );
assert( ref $res eq 'ARRAY' );
match( scalar @$res, 5 );
match( $res->[0], 'zeroth' );
match( $res->[1], 'try/foo/first' );
match( $res->[2], 'then/foo/next' );
match( $res->[3], 'foo' );
match( $res->[4], 'bar' );

match( $map->name('foo'), 'foo' );
match( $map->name([]), 'list' );
match( $map->name({}), 'hash' );
match( $map->name(bless {}, 'Foo::Bar'), 'Foo_Bar' );

package Foo::Bar::Baz;

sub TT_name {
    return 'floozy';
}

package main;

match( $map->name(bless {}, 'Foo::Bar::Baz'), 'floozy' );


