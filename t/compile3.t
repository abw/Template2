#============================================================= -*-perl-*-
#
# t/compile3.t
#
# Last test in the compile<n>.t trilogy.  Checks that modifications
# to a source template result in a re-compilation of the template.
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
$^W = 1;

# declare extra test to follow test_expect();
$Template::Test::EXTRA = 1;

# script may be being run in distribution root or 't' directory
my $dir   = -d 't' ? 't/test/src' : 'test/src';
my $ttcfg = {
    POST_CHOMP   => 1,
    INCLUDE_PATH => $dir,
    COMPILE_EXT => '.ttc',
};

my $file = "$dir/complex";

# check compiled template file exists and save modification time
ok( -f "$file.ttc" );
my $mod = (stat(_))[9];

# sleep for a couple of seconds to ensure clock has ticked
sleep(2);

# append a harmless newline to the end of the source file to change
# its modification time
open(FOO, ">>$file") || die "$file: $!\n";
print FOO "\n";
close(FOO);

test_expect(\*DATA, $ttcfg);

ok( (stat($file))[9] > $mod );

__DATA__
-- test --
[% META author => 'albert' version => 'emc2'  %]
[% INCLUDE complex %]
-- expect --
This is the header, title: Yet Another Template Test
This is a more complex file which includes some BLOCK definitions
This is the footer, author: albert, version: emc2


