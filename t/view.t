#============================================================= -*-perl-*-
#
# t/view.t
#
# Tests the 'View' plugin.
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
use lib qw( ../lib );
use Template::Test;
$^W = 1;

use Template::View;

#$Template::View::DEBUG = 1;
$Template::Test::DEBUG = 0;

#------------------------------------------------------------------------
package Foo;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub present {
    my $self = shift;
    return '{ ' . join(', ', map { "$_ => $self->{ $_ }" } 
		       sort keys %$self) . ' }';
}

sub reverse {
    my $self = shift;
    return '{ ' . join(', ', map { "$_ => $self->{ $_ }" } 
		       reverse sort keys %$self) . ' }';
}

#------------------------------------------------------------------------
package main;

my $vars = {
    foo => Foo->new( pi => 3.14, e => 2.718 ),
};

test_expect(\*DATA, undef, $vars);

__DATA__
-- test --
[% USE v = View -%]
[[% v.prefix %]]
-- expect --
[]

-- test --
[% USE v = View( default="any" ) -%]
[[% v.default %]]
-- expect --
[any]

-- test --
[% USE view( prefix=> 'foo/', suffix => '.tt2') -%]
[[% view.prefix %]bar[% view.suffix %]]
[[% view.template_name('baz') %]]
-- expect --
[foo/bar.tt2]
[foo/baz.tt2]

-- test --
[% USE view( prefix=> 'foo/', suffix => '.tt2') -%]
[[% view.prefix %]bar[% view.suffix %]]
[[% view.template_name('baz') %]]
-- expect --
[foo/bar.tt2]
[foo/baz.tt2]

-- test --
[% USE view -%]
[% view.print('Hello World') %]
[% BLOCK text %]TEXT: [% item %][% END -%]
-- expect --
TEXT: Hello World

-- test --
[% USE view -%]
[% view.print( { foo => 'bar' } ) %]
[% BLOCK hash %]HASH: {
[% FOREACH key = item.keys.sort -%]
   [% key %] => [% item.$key %]
[%- END %]
}
[% END -%]
-- expect --
HASH: {
   foo => bar
}

-- test --
[% USE view -%]
[% view.view('hash', { item => { bar => 'baz' } }, prefix => 'my_' ) %]
[% BLOCK my_hash %]HASH: {
[% FOREACH key = item.keys.sort -%]
   [% key %] => [% item.$key %]
[%- END %]
}
[% END -%]
-- expect --
HASH: {
   bar => baz
}

-- test --
[% USE view(prefix='my_') -%]
[% view.print( foo => 'wiz', bar => 'waz' ) %]
[% BLOCK my_hash %]KEYS: [% item.keys.sort.join(', ') %][% END %]

-- expect --
KEYS: bar, foo

-- test --
[% USE view -%]
[% view.print( view ) %]
[% BLOCK Template_View %]Printing a Template::View object[% END -%]
-- expect --
Printing a Template::View object

-- test --
[% USE view(prefix='my_') -%]
[% view.print( view ) %]
[% view.print( view, prefix='your_' ) %]
[% BLOCK my_Template_View %]Printing my Template::View object[% END -%]
[% BLOCK your_Template_View %]Printing your Template::View object[% END -%]
-- expect --
Printing my Template::View object
Printing your Template::View object

-- test --
[% USE view(prefix='my_', notfound='any' ) -%]
[% view.print( view ) %]
[% view.print( view, prefix='your_' ) %]
[% BLOCK my_any %]Printing any of my objects[% END -%]
[% BLOCK your_any %]Printing any of your objects[% END -%]
-- expect --
Printing any of my objects
Printing any of your objects

-- test --
[% USE view(prefix='my_', default='catchall' ) -%]
[% view.print( view ) %]
[% view.print( view, default="catchsome" ) %]
[% BLOCK my_catchall %]Catching all defaults[% END -%]
[% BLOCK my_catchsome %]Catching some defaults[% END -%]
-- expect --
Catching all defaults
Catching some defaults

-- test --
[% USE view(prefix='my_', default='catchall' notfound='lost') -%]
[% view.print( view ) %]
[% BLOCK my_lost %]Something has been found[% END -%]
-- expect --
Something has been found

-- test --
[% USE view -%]
[% TRY ;
     view.print( view ) ;
   CATCH view ;
     "[$error.type] $error.info" ;
   END
%]
-- expect --
[view] file error - Template_View: not found


-- test --
[% USE view -%]
[% view.print( foo ) %]
-- expect --
{ e => 2.718, pi => 3.14 }

-- test --
[% USE view -%]
[% view.print( foo, method => 'reverse' ) %]
-- expect --
{ pi => 3.14, e => 2.718 }

-- test --
[% USE view(prefix='my_') -%]
[% BLOCK my_foo; "Foo: $a"; END -%]
[[% view.view_foo(a => 20) %]]
[[% view.foo(a => 30) %]]
-- expect --
[Foo: 20]
[Foo: 30]

-- test --
[% USE view(prefix='my_', view_naked=0) -%]
[% BLOCK my_foo; "Foo: $a"; END -%]
[[% view.view_foo(a => 20) %]]
[% TRY ;
     view.foo(a => 30) ;
   CATCH ;
     error.info ;
   END
%]
-- expect --
[Foo: 20]
no such view member: foo

-- test --
[% USE view(map => { HASH => 'my_hash', ARRAY => 'your_list' }) -%]
[% BLOCK text %]TEXT: [% item %][% END -%]
[% BLOCK my_hash %]HASH: [% item.keys.sort.join(', ') %][% END -%]
[% BLOCK your_list %]LIST: [% item.join(', ') %][% END -%]
[% view.print("some text") %]
[% view.print({ alpha => 'a', bravo => 'b' }) %]
[% view.print([ 'charlie', 'delta' ]) %]
-- expect --
TEXT: some text
HASH: alpha, bravo
LIST: charlie, delta

-- test --
[% USE view(item => 'thing',
	    map => { HASH => 'my_hash', ARRAY => 'your_list' }) -%]
[% BLOCK text %]TEXT: [% thing %][% END -%]
[% BLOCK my_hash %]HASH: [% thing.keys.sort.join(', ') %][% END -%]
[% BLOCK your_list %]LIST: [% thing.join(', ') %][% END -%]
[% view.print("some text") %]
[% view.print({ alpha => 'a', bravo => 'b' }) %]
[% view.print([ 'charlie', 'delta' ]) %]
-- expect --
TEXT: some text
HASH: alpha, bravo
LIST: charlie, delta



