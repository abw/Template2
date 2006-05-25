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

#$Template::Directive::PRETTY = 1;
#$Template::Parser::DEBUG = 1;

match( CHOMP_NONE, 0 );
match( CHOMP_ONE, 1 );
match( CHOMP_ALL, 1 );
match( CHOMP_COLLAPSE, 2 );
match( CHOMP_GREEDY, 3 );

my $foo  = "\n[% foo %]\n";
my $bar  = "\n[%- bar -%]\n";
my $baz  = "\n[%+ baz +%]\n";
my $ding = "!\n\n[%~ ding ~%]\n\n!";
my $dong = "!\n\n[%= dong =%]\n\n!";
my $dang = "Hello[%# blah blah blah -%]\n!";

my $blocks = {
    foo  => $foo,
    bar  => $bar,
    baz  => $baz,
    ding => $ding,
    dong => $dong,
    dang => $dang,
};


#------------------------------------------------------------------------
# tests without any CHOMP options set
#------------------------------------------------------------------------

my $tt2 = Template->new({
    BLOCKS => $blocks,
});
my $vars = {
    foo  => 3.14,
    bar  => 2.718,
    baz  => 1.618,
    ding => 'Hello',
    dong => 'World'  
};

my $out;
ok( $tt2->process('foo', $vars, \$out), $tt2->error() );
match( $out, "\n3.14\n" );

$out = '';
ok( $tt2->process('bar', $vars, \$out), $tt2->error() );
match( $out, "2.718" );

$out = '';
ok( $tt2->process('baz', $vars, \$out), $tt2->error() );
match( $out, "\n1.618\n" );

$out = '';
ok( $tt2->process('ding', $vars, \$out), $tt2->error() );
match( $out, "!Hello!" );

$out = '';
ok( $tt2->process('dong', $vars, \$out), $tt2->error() );
match( $out, "! World !" );

$out = '';
ok( $tt2->process('dang', $vars, \$out), $tt2->error() );
match( $out, "Hello!" );


#------------------------------------------------------------------------
# tests with the PRE_CHOMP option set
#------------------------------------------------------------------------

$tt2 = Template->new({
    PRE_CHOMP => 1,
    BLOCKS => $blocks,
});

$out = '';
ok( $tt2->process('foo', $vars, \$out), $tt2->error() );
match( $out, "3.14\n" );

$out = '';
ok( $tt2->process('bar', $vars, \$out), $tt2->error() );
match( $out, "2.718" );

$out = '';
ok( $tt2->process('baz', $vars, \$out), $tt2->error() );
match( $out, "\n1.618\n" );

$out = '';
ok( $tt2->process('ding', $vars, \$out), $tt2->error() );
match( $out, "!Hello!" );

$out = '';
ok( $tt2->process('dong', $vars, \$out), $tt2->error() );
match( $out, "! World !" );


#------------------------------------------------------------------------
# tests with the POST_CHOMP option set
#------------------------------------------------------------------------

$tt2 = Template->new({
    POST_CHOMP => 1,
    BLOCKS => $blocks,
});

$out = '';
ok( $tt2->process('foo', $vars, \$out), $tt2->error() );
match( $out, "\n3.14" );

$out = '';
ok( $tt2->process('bar', $vars, \$out), $tt2->error() );
match( $out, "2.718" );

$out = '';
ok( $tt2->process('baz', $vars, \$out), $tt2->error() );
match( $out, "\n1.618\n" );

$out = '';
ok( $tt2->process('ding', $vars, \$out), $tt2->error() );
match( $out, "!Hello!" );

$out = '';
ok( $tt2->process('dong', $vars, \$out), $tt2->error() );
match( $out, "! World !" );


my $tt = [
    tt_pre_none  => Template->new(PRE_CHOMP  => CHOMP_NONE),
    tt_pre_one   => Template->new(PRE_CHOMP  => CHOMP_ONE),
    tt_pre_all   => Template->new(PRE_CHOMP  => CHOMP_ALL),
    tt_pre_coll  => Template->new(PRE_CHOMP  => CHOMP_COLLAPSE),
    tt_post_none => Template->new(POST_CHOMP => CHOMP_NONE),
    tt_post_one  => Template->new(POST_CHOMP => CHOMP_ONE),
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
# tt_pre_one
#------------------------------------------------------------------------
-- test --
-- use tt_pre_one --
-- test --
begin[% a = 10; b = 20 %]
     [% a %]
     [% b %]
end
-- expect --
begin1020
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
# tt_post_one
#------------------------------------------------------------------------
-- test --
-- use tt_post_one --
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

