#============================================================= -*-perl-*-
#
# t/filter.t
#
# Template script testing FILTER directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
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
#$Template::Context::DEBUG = 1;
#$Template::DEBUG = 1;

my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my $params = { 
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'd'      => $d,
    'list'   => [ $a, $b, $c, $d ],
    'text'   => 'The cat sat on the mat',
};
my $config = {
    INTERPOLATE => 1, 
    POST_CHOMP  => 1,
    FILTER_FACTORY  => {
        'badfact'   => 'nonsense',
	'badfilt'   => sub { 'rubbish' },
	'microjive' => sub { \&microjive },
	'censor'    => \&censor_factory,
    },
};

sub microjive {
    my $text = shift;
    $text =~ s/microsoft/The 'Soft/sig;
    $text;
}

sub censor_factory {
    my @forbidden = @_;
    return sub {
	my $text = shift;
	foreach my $word (@forbidden) {
	    $text =~ s/$word/[** CENSORED **]/sig;
	}
	return $text;
    }
}

test_expect(\*DATA, $config, $params);
 

__DATA__
[% FILTER html %]
This is some html text
All the <tags> should be escaped & protected
[% END %]
-- expect --
This is some html text
All the &lt;tags&gt; should be escaped &amp; protected

-- test --
[% text = "The <cat> sat on the <mat>" %]
[% FILTER html %]
   text: $text
[% END %]
-- expect --
   text: The &lt;cat&gt; sat on the &lt;mat&gt;

-- test --
[% text = "The <cat> sat on the <mat>" %]
[% text FILTER html %]
-- expect --
The &lt;cat&gt; sat on the &lt;mat&gt;

-- test --
[% FILTER format %]
Hello World!
[% END %]
-- expect --
Hello World!

-- test --
# test aliasing of a filter
[% FILTER comment = format('<!-- %s -->') %]
Hello World!
[% END +%]
[% "Goodbye, cruel World" FILTER comment %]
-- expect --
<!-- Hello World! -->
<!-- Goodbye, cruel World -->

-- test --
[% FILTER format %]
Hello World!
[% END %]
-- expect --
Hello World!

-- test --
[% "Foo" FILTER test1 = format('+++ %-4s +++') +%]
[% FOREACH item = [ 'Bar' 'Baz' 'Duz' 'Doze' ] %]
  [% item FILTER test1 +%]
[% END %]
[% "Wiz" FILTER test1 = format("*** %-4s ***") +%]
[% "Waz" FILTER test1 +%]
-- expect --
+++ Foo  +++
  +++ Bar  +++
  +++ Baz  +++
  +++ Duz  +++
  +++ Doze +++
*** Wiz  ***
*** Waz  ***

-- test --
[% FILTER microjive %]
The "Halloween Document", leaked to Eric Raymond from an insider
at Microsoft, illustrated Microsoft's strategy of "Embrace,
Extend, Extinguish"
[% END %]
-- expect --
The "Halloween Document", leaked to Eric Raymond from an insider
at The 'Soft, illustrated The 'Soft's strategy of "Embrace,
Extend, Extinguish"

-- test --
[% FILTER censor('bottom' 'nipple') %]
At the bottom of the hill, he had to pinch the
nipple to reduce the oil flow.
[% END %]
-- expect --
At the [** CENSORED **] of the hill, he had to pinch the
[** CENSORED **] to reduce the oil flow.

-- test --
[% TRY %]
[% FILTER badfact %]
blah blah blah
[% END %]
[% CATCH %]
BZZZT: [% error.type %]: [% error.info %]
[% END %]
-- expect --
BZZZT: undef: invalid FILTER factory for 'badfact' (not a CODE ref)

-- test --
[% TRY %]
[% FILTER badfilt %]
blah blah blah
[% END %]
[% CATCH %]
BZZZT: [% error.type %]: [% error.info %]
[% END %]
-- expect --
BZZZT: undef: invalid FILTER 'badfilt' (not a CODE ref)

-- test --
[% FILTER bold = format('<b>%s</b>') %]
This is bold
[% END +%]
[% FILTER italic = format('<i>%s</i>') %]
This is italic
[% END +%]
[% 'This is both' FILTER bold FILTER italic %]
-- expect --
<b>This is bold</b>
<i>This is italic</i>
<i><b>This is both</b></i>

-- test --
[% "foo" FILTER format("<< %s >>") FILTER format("=%s=") %]
-- expect --
=<< foo >>=

-- test --
[% blocktext = BLOCK %]
The cat sat on the mat

Mary had a little Lamb



You shall have a fishy on a little dishy, when the boat comes in.  What 
if I can't wait until then?  I'm hungry!
[% END -%]
[% global.blocktext = blocktext; blocktext %]

-- expect --
The cat sat on the mat

Mary had a little Lamb



You shall have a fishy on a little dishy, when the boat comes in.  What 
if I can't wait until then?  I'm hungry!

-- test --
[% global.blocktext FILTER html_para %]

-- expect --
<p>
The cat sat on the mat
</p>

<p>
Mary had a little Lamb
</p>

<p>
You shall have a fishy on a little dishy, when the boat comes in.  What 
if I can't wait until then?  I'm hungry!
</p>

-- test --
[% global.blocktext FILTER html_break %]

-- expect --
The cat sat on the mat
<br>
<br>
Mary had a little Lamb
<br>
<br>
You shall have a fishy on a little dishy, when the boat comes in.  What 
if I can't wait until then?  I'm hungry!

-- test --
[% global.blocktext FILTER truncate(10) %]

-- expect --
The cat...

-- test --
[% global.blocktext FILTER truncate %]

-- expect --
The cat...

-- test --
[% "foo..." FILTER repeat(5) %]

-- expect --
foo...foo...foo...foo...foo...

-- test --
[% FILTER truncate(21) %]
I have much to say on this matter that has previously been said
on more than one occassion.
[% END %]

-- expect --
I have much to say...

-- test --
[% FILTER truncate(25) %]
Nothing much to say
[% END %]

-- expect --
Nothing much to say

-- test --
[% FILTER repeat(3) %]
Am I repeating myself?
[% END %]

-- expect --
Am I repeating myself?
Am I repeating myself?
Am I repeating myself?

-- test --
[% text FILTER remove(' ') +%]
[% text FILTER remove('\s+') +%]
[% text FILTER remove('cat') +%]
[% text FILTER remove('at') +%]
[% text FILTER remove('at', 'splat') +%]

-- expect --
Thecatsatonthemat
Thecatsatonthemat
The  sat on the mat
The c s on the m
The c s on the m

-- test --
[% text FILTER replace(' ', '_') +%]
[% text FILTER replace('sat', 'shat') +%]
[% text FILTER replace('at', 'plat') +%]

-- expect --
The_cat_sat_on_the_mat
The cat shat on the mat
The cplat splat on the mplat

-- test --
[% text = 'The <=> operator' %]
[% text|html %]
-- expect --
The &lt;=&gt; operator

-- test --
[% text = 'The <=> operator, blah, blah' %]
[% text | html | replace('blah', 'rhubarb') %]
-- expect --
The &lt;=&gt; operator, rhubarb, rhubarb

-- test --
[% | truncate(25) %]
The cat sat on the mat, and wondered to itself,
"How might I be able to climb up onto the shelf?",
For up there I am sure I'll see,
A tasty fishy snack for me.
[% END %]
-- expect --
The cat sat on the mat...

-- test --
[% FILTER upper %]
The cat sat on the mat
[% END %]
-- expect --
THE CAT SAT ON THE MAT

-- test --
[% FILTER lower %]
The cat sat on the mat
[% END %]
-- expect --
the cat sat on the mat

