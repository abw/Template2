#============================================================= -*-perl-*-
#
# t/chomp.t
#
# Test the PRE_CHOMP and POST_CHOMP options.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
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
use Template::Constants qw( :chomp );

$^W = 1;


match( CHOMP_NONE, 0 );
match( CHOMP_ALL, 1 );
match( CHOMP_COLLAPSE, 2 );

my $tt = [
    tt_pre_none  => Template->new(PRE_CHOMP  => CHOMP_NONE),
    tt_pre_all   => Template->new(PRE_CHOMP  => CHOMP_ALL),
    tt_pre_coll  => Template->new(PRE_CHOMP  => CHOMP_COLLAPSE),
    tt_post_none => Template->new(POST_CHOMP => CHOMP_NONE),
    tt_post_all  => Template->new(POST_CHOMP => CHOMP_ALL),
    tt_post_coll => Template->new(POST_CHOMP => CHOMP_COLLAPSE),
];

test_expect(\*DATA, $tt);

__DATA__
#------------------------------------------------------------------------
# tt_pre_none
#------------------------------------------------------------------------
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin
     10
     20
end

#------------------------------------------------------------------------
# tt_pre_all
#------------------------------------------------------------------------
-- test --
-- use tt_pre_all --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin1020
end

#------------------------------------------------------------------------
# tt_pre_coll
#------------------------------------------------------------------------
-- test --
-- use tt_pre_coll --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin 10 20
end


#------------------------------------------------------------------------
# tt_post_none
#------------------------------------------------------------------------
-- test --
-- use tt_post_none --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin
     10
     20
end

#------------------------------------------------------------------------
# tt_post_all
#------------------------------------------------------------------------
-- test --
-- use tt_post_all --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin     10     20end

#------------------------------------------------------------------------
# tt_post_coll
#------------------------------------------------------------------------
-- test --
-- use tt_post_coll --
-- test --
begin[% a = 10; b = 20 %]     
[% a %]     
[% b %]     
end
-- expect --
begin 10 20 end

