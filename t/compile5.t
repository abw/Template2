#============================================================= -*-perl-*-
#
# t/compile5.t
#
# Test that the compiled template files written by compile4.t can be 
# loaded and used.  Similar to compile2.t but using COMPILE_DIR as well
# as COMPILE_EXT.
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
use Cwd qw( abs_path );
use File::Path;

$^W = 1;

my $dir   = abs_path( -d 't' ? 't/test' : 'test' );
my $cdir  = abs_path("$dir/tmp") . "/cache";
my $ttcfg = {
    POST_CHOMP   => 1,
    INCLUDE_PATH => "$dir/src",
    COMPILE_DIR  => $cdir,
    COMPILE_EXT  => '.ttc',
};

# check compiled template files exist
my ($foo, $bar) = map { "$cdir/$dir/src/$_.ttc" } qw( foo complex );
ok( -f $foo );
ok( -f $bar );

# we're going to hack on the compiled 'foo' file to change some key text.
# this way we can tell that the template was loaded from the compiled
# version and not the source.

open(FOO, $foo) || die "$foo: $!\n";
local $/ = undef;
my $content = <FOO>;
close(FOO);

$content =~ s/the foo file/the newly hacked foo file/;
open(FOO, "> $foo") || die "$foo: $!\n";
print FOO $content;
close(FOO);

test_expect(\*DATA, $ttcfg);

# cleanup cache directory
rmtree($cdir) if -d $cdir;


__DATA__
-- test --
[% INCLUDE foo a = 'any value' %]
-- expect --
This is the newly hacked foo file, a is any value

-- test --
[% META author => 'billg' version => 6.66  %]
[% INCLUDE complex %]
-- expect --
This is the header, title: Yet Another Template Test
This is a more complex file which includes some BLOCK definitions
This is the footer, author: billg, version: 6.66
- 3 - 2 - 1 


