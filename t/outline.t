#============================================================= -*-perl-*-
#
# t/outline.t
#
# Test the OUTLINE_TAG option.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2020 Andy Wardley.  All Rights Reserved.
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

my $tt_vanilla = Template->new;
my $tt_outline = Template->new({
    TAG_STYLE => 'outline',
});
my $tt_outtag = Template->new({
    OUTLINE_TAG => '%%',
});
my $tt_shell = Template->new({
    OUTLINE_TAG => quotemeta '$ ',
});

my $engines = [
    default => $tt_vanilla,
    outline => $tt_outline,
    outtag  => $tt_outtag,
    shell   => $tt_shell,
];


test_expect(\*DATA, $engines, callsign);

__DATA__
-- test --
-- name TAGS outline --
# Outline tags are not enabled by default
%% [% r %] and [% j %]
# Turn them on like so
[% TAGS outline -%]
%% IF a     # outline tags can contain comments
a is set to [% a %]
%% ELSE
a is not set
%% END
# Turn them off again
[% TAGS default -%]
%% [% f %] and [% t %]
-- expect --
%% romeo and juliet
a is set to alpha
%% foxtrot and tango

-- test --
-- name TAGS <start> <end> <outline> --
%% [% r %] and [% j %]
# You can also use TAGS to specify your own <start_tag> <end_tag> <outline_tag>
[% TAGS {{ }} >> -%]
>> IF b
b is set to {{b}}
>> ELSE
b is not set
>> END
-- expect --
%% romeo and juliet
b is set to bravo

-- test --
-- name TAG_STYLE outline --
-- use outline --
# This engine should already have TAG_STYLE set to 'outline'
%% IF c
c is set to [% c %]
%% ELSE
c is not set
%% END
# Turn them off again
[% TAGS default -%]
%% [% f %] and [% t %]
-- expect --
c is set to charlie
%% foxtrot and tango

-- test --
-- name OUTLINE_TAG --
-- use outtag --
# This engine should already have OUTLINE_TAG set to '%%'
%% IF d
d is set to [% d %]
%% ELSE
d is not set
%% END
-- expect --
d is set to delta

-- test --
-- name OUTLINE_TAG shell --
-- use shell --
# This engine should already have OUTLINE_TAG set to '$ '
$ IF e
e is set to [% e %]
$ ELSE
e is not set
$ END
-- expect --
e is set to echo
