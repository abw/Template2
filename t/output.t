#============================================================= -*-perl-*-
#
# t/output.t
#
# Test the OUTPUT and OUTPUT_PATH options of the Template.pm module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib  qw( ./lib ../lib );
use vars qw( $DEBUG );
use Template::Test;


ntests(37);
$DEBUG = 1;
$Template::Config::DEBUG = 1;

my $factory = 'Template::Config';

my $tt = Template->new({
    INCLUDE_PATH => 'test/src:test/lib',
    PRE_PROCESS  => 'config',
    POST_PROCESS => 'footer',
    OUTPUT_PATH  => '/tmp',
}) || die Template->error();

$tt->process('tryme', &callsign)
    || print STDERR $tt->error, "\n";
