#============================================================= -*-perl-*-
#
# t/date.t
#
# Tests the 'Date' plugin.
#
# NOTE: this relies on a hacked version of Template::Test.pm that supports
# the '-- process --' flag in an '-- expect --' block.  We need this
# because we can't hard-code expected output in advance when we're 
# dealing with generating date string based on the current time at
# execution. 
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Template::Plugin::Date;
use POSIX;
$^W = 1;

$Template::Test::DEBUG = 0;

my $format = {
    'default' => $Template::Plugin::Date::FORMAT,
    'time'    => '%H:%M:%S',
    'date'    => '%d-%b-%Y',
    'timeday' => 'the time is %H:%M:%S on %A',
};

my $time = time;
my @ltime = localtime($time);

my $params = { 
    time    => $time,
    format  => $format,
    timestr => &POSIX::strftime($format->{ time }, @ltime),
    datestr => &POSIX::strftime($format->{ date }, @ltime),
    daystr  => &POSIX::strftime($format->{ timeday }, @ltime),
    defstr  => &POSIX::strftime($format->{ default }, @ltime),
    now     => sub { 
	&POSIX::strftime(shift || $format->{ default }, localtime(time));
    },
    nowloc  => sub { my ($time, $format, $locale) = @_;
	my $old_locale = &POSIX::setlocale(&POSIX::LC_ALL);
	&POSIX::setlocale(&POSIX::LC_ALL, $locale);
	my $datestr = &POSIX::strftime($format, localtime($time));
	&POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
	return $datestr;
    },
};

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);
 

#------------------------------------------------------------------------
# test input
#
# NOTE: these tests check that the Date plugin is behaving as expected
# but don't attempt to validate that the output returned from strftime()
# is semantically correct.  It's a closed loop (aka "vicious circle" :-)
# in which we compare what date.format() returns to what we get by 
# calling strftime() directly.  Despite this, we can rest assured that
# the plugin is correctly parsing the various parameters and passing 
# them to strftime() as expected.
#------------------------------------------------------------------------

__DATA__
-- test --
[% USE date %]
Let's hope the year doesn't roll over in between calls to date.format()
and now()...
Year: [% date.format(format => '%Y') %]

-- expect --
-- process --
Let's hope the year doesn't roll over in between calls to date.format()
and now()...
Year: [% now('%Y') %]

-- test --
[% USE date(time => time) %]
default: [% date.format %]

-- expect --
-- process --
default: [% defstr %]

-- test --
[% USE date(time => time) %]
[% date.format(format => format.timeday) %]

-- expect --
-- process --
[% daystr %]

-- test --
[% USE date(time => time, format = format.date) %]
Date: [% date.format %]

-- expect --
-- process --
Date: [% datestr %]

-- test --
[% USE date(format = format.date) %]
Time: [% date.format(time, format.time) %]

-- expect --
-- process --
Time: [% timestr %]

-- test --
[% USE date(format = format.date) %]
Time: [% date.format(time, format = format.time) %]

-- expect --
-- process --
Time: [% timestr %]


-- test --
[% USE date(format = format.date) %]
Time: [% date.format(time = time, format = format.time) %]

-- expect --
-- process --
Time: [% timestr %]

-- test --
[% USE english = date(format => '%A', locale => 'en_GB') %]
[% USE french  = date(format => '%A', locale => 'fr_FR') %]
In English, today's day is: [% english.format +%]
In French, today's day is: [% french.format +%]

-- expect --
-- process --
In English, today's day is: [% nowloc(time, '%A', 'en_GB') +%]
In French, today's day is: [% nowloc(time, '%A', 'fr_FR') +%]

-- test --
[% USE english = date(format => '%A') %]
[% USE french  = date() %]
In English, today's day is: 
[%- english.format(locale => 'en_GB') +%]
In French, today's day is: 
[%- french.format(format => '%A', locale => 'fr_FR') +%]

-- expect --
-- process --
In English, today's day is: [% nowloc(time, '%A', 'en_GB') +%]
In French, today's day is: [% nowloc(time, '%A', 'fr_FR') +%]

-- test --
[% USE date %]
[% date.format('4:20:00 6-13-2000', '%H') %]

-- expect --
04

-- test --
[% USE day = date(format => '%A', locale => 'en_GB') %]
[% day.format('4:20:00 9-13-2000') %]

-- expect --
Tuesday

-- test --
[% TRY %]
[% USE date %]
[% date.format('some stupid date') %]
[% CATCH date %]
Bad date: [% e.info %]
[% END %]
-- expect --
Bad date: bad time/date string:  expects 'h:m:s d:m:y'  got: 'some stupid date'

-- test --
[% USE date %]
[% template.name %] [% date.format(template.modtime, format='%Y') %]
-- expect --
-- process --
input text [% now('%Y') %]

