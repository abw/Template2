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
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template;
use Template::Stash;
use Template::Test;
$^W = 1;

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
    'warn'    => Template->new(DEBUG => 1),
];

test_expect(\*DATA, $ttlist);

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
