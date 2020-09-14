#============================================================= -*-perl-*-
#
# t/date_utf8.t
#
# Tests the 'Date' plugin.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use utf8;
use strict;
use warnings;

use lib qw( ./lib ../lib );

use Template;
use Template::Test;
use Template::Plugin::Date;

use POSIX qw{ setlocale LC_ALL };
use Config;

# this test fails on CI workflow probably due to missing locale
skip_all( "Need to set env variable AUTHOR_TESTING=1" ) unless $ENV{AUTHOR_TESTING} && !$ENV{AUTOMATED_TESTING};

skip_all( "d_setlocale unset" ) unless $Config::Config{d_setlocale};

#$Template::Test::DEBUG = 0;

my $russian_locale = 'ru_RU.UTF-8';

my $loc = setlocale( LC_ALL, $russian_locale );
skip_all("no russian locale $russian_locale available") unless $loc && $loc eq $russian_locale;

setlocale( LC_ALL, 'C' );

my $params = {};
test_expect(\*DATA, { POST_CHOMP => 1 }, $params);

__DATA__
-- test --
[% USE russian = date(format => '%A, %e %B %Y', locale => 'ru_RU.UTF-8') %]
In Russian with UTF8: [% russian.format(1245) +%]

-- expect --
In Russian with UTF8: среда, 31 декабря 1969
