#============================================================= -*-perl-*-
#
# t/template.t
#
# Test the Template.pm module.  Does nothing of any great importance
# at the moment, but all of its options are tested in the various other
# test scripts.
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
use Template;
use Template::Test;

my $tt = Template->new();
ok( $tt );
