#============================================================= -*-perl-*-
#
# t/evalperl.t
#
# Test the evaluation of PERL and RAWPERL blocks.
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

#$Template::Parser::DEBUG = 1;
#$Template::Context::DEBUG = 0;

my $tt_no_perl = Template->new({ 
    INTERPOLATE  => 1, 
    POST_CHOMP   => 1,
    EVAL_PERL    => 0,
    INCLUDE_PATH => -d 't' ? 't/test/lib' : 'test/lib',
});

my $tt_do_perl = Template->new({ 
    INTERPOLATE => 1, 
    POST_CHOMP  => 1,
    EVAL_PERL   => 1,
});

my $ttprocs = [
    no_perl => $tt_no_perl, 
    do_perl => $tt_do_perl,
];

test_expect(\*DATA, $ttprocs, &callsign);

__DATA__

-- test --
[% META 
   author  = 'Andy Wardley'
   title   = 'Test Template $foo #6'
   version = 1.23
%]
[% PERL %]
    my $output = "author: [% template.author %]\n";
    $stash->set('a', 'The cat sat on the mat');
    $output .= "more perl generated output\n";
    $output;
[% END %]
a: [% a +%]
a: $a
[% RAWPERL %]
$output .= "The cat sat on the mouse mat\n";
$stash->set('b', 'The cat sat where?');
[% END %]
b: [% b +%]
b: $b
-- expect --
a: alpha
a: alpha
b: bravo
b: bravo

-- test --
nothing
[% PERL %]
We don't care about correct syntax within PERL blocks if EVAL_PERL isn't set.
They're simply ignored.
[% END %]
-- expect --
nothing

-- test --
some stuff
[% TRY %]
[% INCLUDE badrawperl %]
[% CATCH %]
ERROR: [[% error.type %]] [% error.info %]
[% END %]
-- expect --
some stuff
ERROR: [file] syntax error at RAWPERL block (starting line 2) line 2, at EOF

-- test --
-- use do_perl --
[% META 
   author  = 'Andy Wardley'
   title   = 'Test Template $foo #6'
   version = 3.14
%]
[% PERL %]
    my $output = "author: [% template.author %]\n";
    $stash->set('a', 'The cat sat on the mat');
    $output .= "more perl generated output\n";
    $output;
[% END %]
a: [% a +%]
a: $a
[% RAWPERL %]
$output .= "The cat sat on the mouse mat\n";
$stash->set('b', 'The cat sat where?');
[% END %]
b: [% b +%]
b: $b
-- expect --
author: Andy Wardley
more perl generated output
a: The cat sat on the mat
a: The cat sat on the mat
The cat sat on the mouse mat
b: The cat sat where?
b: The cat sat where?


