#============================================================= -*-perl-*-
#
# t/evalperl.t
#
# Test templates compiled to perl code.
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

$Template::Parser::DEBUG = 1;
$Template::Context::DEBUG = 1;

my $tt_no_perl = Template->new({ 
    INTERPOLATE => 1, 
    POST_CHOMP  => 1,
    EVAL_PERL   => 0,
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


