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
use Template::Config;

BEGIN {
    unless ($] > 5.007) {
        skip_all("perl < 5.8 can't do unicode well enough\n");
    }
}

# only run the test when compiled with Template::Stash
if ( $Template::Config::STASH ne 'Template::Stash::XS' ) {
    skip_all('Template::Config is not using Template::Stash::XS');
}

require Template::Stash::XS;

binmode STDOUT, ':utf8';

my $data = {
    ascii => 'key',
    utf8  => 'ключ',
    hash  => {
        key  => 'value',
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

-- test --
-- name UTF8 key fetch --
utf8 = [% utf8 %]
hash.$utf8 = hash.[% utf8 %] = [% hash.$utf8 %]
-- expect --
utf8 = ключ
hash.$utf8 = hash.ключ = значение

-- test --
-- name UTF8 key assign --
[% value = hash.$utf8; hash.$value = utf8 -%]
value = [% value %]
hash.$value = hash.[% value %] = [% hash.$value %]
-- expect --
value = значение
hash.$value = hash.значение = ключ
