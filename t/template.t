#============================================================= -*-perl-*-
#
# t/template.t
#
# Test the Template.pm module.
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

ntests(3);
$DEBUG = 1;

my $tt = Template->new(INCLUDE_PATH => 'here')
    || die $Template::ERROR;

ok( $tt );
ok( $tt->service->context->{ TEMPLATES }->[0]->{ INCLUDE_PATH }->[0] eq 'here' );
#print $tt->service->context->{ TEMPLATES }->[0]->_dump();
