#============================================================= -*-perl-*-
#
# t/dumper.t
#
# Test the Dumper plugin.
#
# Written by Simon Matthews <sam@knowledgepool.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use vars qw( $DEBUG );
use Template::Test;
$^W = 1;

my $params = {
    'foo' => 'bar',
    'baz' => 'boo',
};

$DEBUG = 0;

test_expect(\*DATA, undef, { params => $params });

#------------------------------------------------------------------------

__DATA__
[% USE Dumper -%]
Dumper

-- expect --
Dumper

-- test --
[% USE Dumper -%]
[% Dumper.dump({ foo = 'bar', bar = 'baz'}, 'hello' ) -%]

-- expect --
$VAR1 = {
          'foo' => 'bar',
          'bar' => 'baz'
        };
$VAR2 = 'hello';


-- test --
[% USE Dumper -%]
[% Dumper.dump(params) -%]

-- expect --
$VAR1 = {
          'foo' => 'bar',
          'baz' => 'boo'
        };

-- test --
[% USE Dumper -%]
[% Dumper.dump_html(params) -%]

-- expect --
$VAR1 = {<br>
          'foo' =&gt; 'bar',<br>
          'baz' =&gt; 'boo'<br>
        };<br>

-- test --
[% USE dumper(indent=1, pad='> ', varname="frank") -%]
[% dumper.dump(params) -%]

-- expect --
> $frank1 = {
>   'foo' => 'bar',
>   'baz' => 'boo'
> };

-- test --
[% USE dumper(Pad='>> ', Varname="bob") -%]
[% dumper.dump(params) -%]

-- expect --
>> $bob1 = {
>>   'foo' => 'bar',
>>   'baz' => 'boo'
>> };

