#============================================================= -*-perl-*-
#
# t/try.t
#
# Template script testing TRY blocks
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
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;
#$Template::Parser::DEBUG = 0;

my $ttcfg = {
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],	
    POST_CHOMP   => 1,
};

test_expect(\*DATA, $ttcfg, &callsign);

__DATA__
-- test --
before try
[% TRY %]
try this
[% THROW barf "Feeling sick" %]
don't try this
[% CATCH barf %]
caught barf: [% error.info +%]
[% END %]
after try

-- expect --
before try
try this
caught barf: Feeling sick
after try

-- test --
[% META 
   copyright = '2000, Andy Wardley'
%]
[% template.copyright or '2000, Big Corporation Networks Conglomerate, Inc' %]

-- expect --
2000, Andy Wardley

-- test --
[% user = {
    name => 'andy'
    id   => 'abw'
    }
%]
[% user.name %]
-- expect --
andy

