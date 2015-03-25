#============================================================= -*-perl-*-
#
# t/map.t
#
# Test the Template::Map module.
#
# Written by Andy Wardley <abw@wardley.org>
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
use Test::More tests => 28;
$^W = 1;

# just testing
ok(1);

use Template::Map;

#$Template::Map::DEBUG = 1;
#$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;
#$Template::Test::PRESERVE = 1;

#------------------------------------------------------------------------
package Some::Kind::Of::Noodle;
sub new { bless { }, $_[0] }
sub TT_name { return 'noodle' }
#------------------------------------------------------------------------

package main;

my $pkg = 'Template::Map';
my $map = $pkg->new() || die $pkg->error();
ok( $map, 'created a default map' );
is( $map->name('foo'), 'text', "'foo' is text" );
is( $map->name(['foo']), 'list', "['foo'] is list" );
is( $map->name({ foo => 'bar' }), 'hash', "{ foo => 'bar' } is hash" );
is( $map->name(bless { }, 'Thingy'), 'Thingy', 'Thingy is a Thingy' );
is( $map->name(Some::Kind::Of::Noodle->new()), 'noodle', 'some noodles' );


$map = $pkg->new( map => { TEXT  => 'string', 
                           ARRAY => 'array',
                           'Some::Kind::Of::Noodle' => 'egg_noodle',
                           'Foo::Bar' => 'fubar' } ) || die $pkg->error();

ok( $map, 'created a custom map' );
is( $map->name('foo'), 'string', "'foo' is string" );
is( $map->name(['foo']), 'array', "['foo'] is array" );
is( $map->name({ foo => 'bar' }), 'hash', "{ foo => 'bar' } is still a hash" );
is( $map->name(bless { }, 'Thingy'), 'Thingy', 'Thingy is a Thingy' );
is( $map->name(bless { }, 'Foo::Bar'), 'fubar', 'Foo::Bar is fubar' );
is( $map->name(Some::Kind::Of::Noodle->new()), 'egg_noodle', 'egg noodle' );


my $names = $map->names('foo') || die $map->error();
ok( $names, 'got names for foo' );
is( ref $names, 'ARRAY', 'an array' );
is( scalar @$names, 1, 'one item in array' );
is( $names->[0], 'foo', 'name is foo' );

$map = $pkg->new( format => 'x/%s.tt' );
$names = $map->names('foo') || die $map->error();
ok( $names, 'got format names for foo' );
is( $names->[0], 'x/foo.tt', 'first name is x/foo.tt' );

$map = $pkg->new( format => [ 'x/%s.tt', 'y/%s.tt' ] );
$names = $map->names('bar') || die $map->error();
ok( $names, 'got names for bar' );
is( $names->[0], 'x/bar.tt', 'first name is x/bar.tt' );
is( $names->[1], 'y/bar.tt', 'second name is y/bar.tt' );

$map = $pkg->new( prefix => 'z/', suffix => '.tt' );
$names = $map->names('baz') || die $map->error();
ok( $names, 'got names for baz' );
is( $names->[0], 'z/baz.tt', 'name is z/baz.tt' );

$map = $pkg->new( default => 'pong' );
$names = $map->names('ping') || die $map->error();
ok( $names, 'got names for ping' );
is( $names->[0], 'ping', 'ping' );
is( $names->[1], 'pong', 'pong' );

__END__

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


