#============================================================= -*-perl-*-
#
# t/except.t
#
# Test the Template::Exception module.
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
use lib qw( ./lib ../lib );
use Template::Test;
use Template::Exception;

my $text = 'the current output buffer';

my $e1 = Template::Exception->new('e1.type', 'e1.info');
my $e2 = Template::Exception->new('e2.type', 'e2.info', \$text);

ok( $e1 );
ok( $e2 );
ok( $e1->type() eq 'e1.type' );
ok( $e2->info() eq 'e2.info' );

my @ti = $e1->type_info();
ok( $ti[0] eq 'e1.type' );
ok( $ti[1] eq 'e1.info' );

ok( $e2->as_string() eq 'e2.type error - e2.info' );
ok( $e2->text() eq 'the current output buffer' );

my $prepend = 'text to prepend ';
$e2->text(\$prepend);
ok( $e2->text() eq 'text to prepend the current output buffer' );

my @handlers = ('something', 'e2', 'e1.type');
ok( $e1->select_handler(@handlers) eq 'e1.type' );
ok( $e2->select_handler(@handlers) eq 'e2' );
