#============================================================= -*-perl-*-
#
# t/ref.t
#
# Template script testing (some elements of) the Template::Stash
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
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
use Template::Test;
$^W = 1;

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
