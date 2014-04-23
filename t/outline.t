#============================================================= -*-perl-*-
#
# t/outline.t
#
# Test the OUTLINE_TAG option.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2014 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

ok(1);

my $config = {
    OUTLINE_TAG => '%%',
};

test_expect(\*DATA, $config, callsign() );

__DATA__
-- test --
%% IF a
a is set to [% a %]
%% ELSE
alpha is not set
%% END
-- expect --
a is set to alpha

-- test --
[% TAGS {{ }} >> -%]
>> IF b
b is set to {{b}}
>> ELSE
b is not set
>> END
-- expect --
b is set to bravo
