#============================================================= -*-perl-*-
#
# t/url.t
#
# Template script testing URL plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

test_expect(\*DATA, { INTERPOLATE => 1 }, { sorted => \&sort_params });

# url params are constructed in a non-deterministic order.  we obviously
# can't test against this so we use this devious hack to reorder a
# query so that its parameters are in alphabetical order.

sub sort_params {
    my $query  = shift;
    my ($base, $args) = split(/\?/, $query);
    my (@args, @keys, %argtab);

    print STDERR "sort_parms(\"$query\")\n" if $Template::Test::DEBUG;

    @args = split('&amp;', $args);
    @keys = map { (split('=', $_))[0] } @args;
    @argtab{ @keys } = @args;
    @keys = sort keys %argtab;
    @args = map { $argtab{ $_ } } @keys;
    $args = join('&amp;', @args);
    $query = join('?', length $base ? ($base, $args) : $args);

    print STDERR "returning [$query]\n" if $Template::Test::DEBUG;

    return $query;
}
 

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
-- test --
[% USE url -%]
loaded
[% url %]
[% url('foo') %]
[% url(foo='bar') %]
[% url('bar', wiz='woz') %]

-- expect --
loaded

foo
foo=bar
bar?wiz=woz

-- test --
[% USE url('here') -%]
[% url %]
[% url('there') %]
[% url(any='where') %]
[% url('every', which='way') %]
[% sorted( url('every', which='way', you='can') ) %]

-- expect --
here
there
here?any=where
every?which=way
every?which=way&amp;you=can

-- test --
[% USE url('there', name='fred') -%]
[% url %]
[% url(name='tom') %]
[% sorted( url(age=24) ) %]
[% sorted( url(age=42, name='frank') ) %]

-- expect --
there?name=fred
there?name=tom
there?age=24&amp;name=fred
there?age=42&amp;name=frank

-- test --
[% USE url('/cgi-bin/woz.pl') -%]
[% url(name="Elrich von Benjy d'Weiro") %]

-- expect --
/cgi-bin/woz.pl?name=Elrich%20von%20Benjy%20d%27Weiro


