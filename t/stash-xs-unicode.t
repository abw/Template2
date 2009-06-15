#============================================================= -*-perl-*-
#
# t/stash-xs-unicode.t
#
# Template script to test unicode data with the XS Stash
#
# Written by Andy Wardley <abw@wardley.org> based on code provided
# by Максим Вуец.
#
# Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib ../blib/lib ../blib/arch ./blib/lib ./blib/arch );
use utf8;
use Template;
use Template::Test;

eval {
    require Template::Stash::XS;
};
if ($@) {
    warn $@;
    skip_all('cannot load Template::Stash::XS');
}

binmode STDOUT, ':utf8';

# XXX: uncomment this to make Template work properly
#$Template::Config::STASH = 'Template::Stash';

my $data = {
    ascii => 'key',
    utf8  => 'ключ',
    hash  => {
        key => 'value',
        ключ => 'значение'
    },
    str => 'щука'
};


test_expect(\*DATA, undef, $data);

__DATA__
-- test --
-- name ASCII key --
ascii = [% ascii %]
hash.$ascii = [% hash.$ascii %]
-- expect --
ascii = key
hash.$ascii = value

-- test --
-- name UTF8 length --
str.length = [% str.length %]
-- expect --
str.length = 4

-- stop --
This test fails.  A trivial attempt at fixing the XS Stash didn't work.  Needs a proper look.

-- test --
-- name UTF8 key --
utf8 = [% utf8 %]
hash.$utf8 = [% hash.$utf8 %]
-- expect --
utf8 = ключ
hash.$utf8 = значение

