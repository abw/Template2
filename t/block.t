#============================================================= -*-perl-*-
#
# t/block.t
#
# Template script testing BLOCK definitions.  A BLOCK defined in a 
# template incorporated via INCLUDE should not be visible (i.e. 
# exported) to the calling template.  In the same case for PROCESS,
# the block should become visible.
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

my $ttcfg = {
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],	
    POST_CHOMP   => 1,
    BLOCKS       => {
	block_a  => sub { return 'this is block a' },
	block_b  => sub { return 'this is block b' },
    },
};

test_expect(\*DATA, $ttcfg, &callsign);

__DATA__

-- test --
[% BLOCK block1 %]
This is the original block1
[% END %]
[% INCLUDE block1 %]
[% INCLUDE blockdef %]
[% INCLUDE block1 %]

-- expect --
This is the original block1
start of blockdef
end of blockdef
This is the original block1

-- test --
[% BLOCK block1 %]
This is the original block1
[% END %]
[% INCLUDE block1 %]
[% PROCESS blockdef %]
[% INCLUDE block1 %]

-- expect --
This is the original block1
start of blockdef
end of blockdef
This is block 1, defined in blockdef, a is alpha

-- test --
[% INCLUDE block_a +%]
[% INCLUDE block_b %]
-- expect --
this is block a
this is block b

