#============================================================= -*-perl-*-
#
# t/date_offset.t
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

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Template::Plugin::Date;
use POSIX;
use Config;
$^W = 1;

eval "use Date::Calc";

my $got_date_calc = 0;
$got_date_calc++ unless $@;

local $ENV{TZ} = 'GMT';
#local $ENV{TZ} = 'Europe/London';

skip_all('TZ GMT not showing as +0000') unless check_tz();

sub check_tz {
  # '2001/09/30T12:59:00' used in DATA
  my $date = [
    '00',
    '59',
    '12',
    '30',
    8,
    101
  ];

  my $time = POSIX::mktime(@$date);
  push @$date, (localtime($time))[6..8];
  my $tz = POSIX::strftime("%z", @$date);

  return $tz eq '+0000';
}

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
    now     => sub {
        &POSIX::strftime(shift || $format->{ default }, localtime(time));
    },
    date_calc   => $got_date_calc,
};

# force second to rollover so that we reliably see any tests failing.
# lesson learnt from 2.07b where I broke the Date plugin's handling of a
# 'time' parameter, but which didn't immediately come to light because the
# script could run before the second rolled over and not expose the bug

sleep 1;

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);



__DATA__
-- test --
[% USE date( use_offset = 1 );
   date.format( '2001/09/30T12:59:00', '%H:%M %z' )
-%]
-- expect --
12:59 +0000

-- test --
[% USE date( use_offset = 1 );
   date.format( '2001/09/30T12:59:00', '%H:%M' )
-%]
-- expect --
12:59

-- test --
[% USE date;
   date.format( time = '2001/09/30T12:59:00', format = '%H:%M %z', use_offset = 1 )
-%]
-- expect --
12:59 +0000
