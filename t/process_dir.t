#============================================================= -*-perl-*-
#
# t/process_dir.t
#
# Test the PROCESS option.
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

use Template;
use Test::More;

my $testdir  = 'testdir';
my $CACHEDIR = 'ttcache';

`rm -rf $CACHEDIR $testdir`;

my $config = {COMPILE_DIR  => $CACHEDIR};
my $tt1 = Template->new($config);

my $data = <<'EOF';
This is the first test
[% TRY; PROCESS "testdir"; CATCH e; "error: e"; END; %]
This is the end.
EOF

my $expected1 = "file error - $testdir: not found";

my $expected2 = "file error - ./$testdir: not a file";

my $expected3 = <<'EOF';
This is the first test

This is the end.
EOF

my $ret = undef;
$tt1->process(\$data, {}, \$ret);

is($tt1->error(), $expected1, 'Error on missing file');

mkdir($CACHEDIR, 0755);
is(-d $CACHEDIR, 1, "Made cache dir ($CACHEDIR)");

mkdir($testdir, 0755);
is(-d $testdir, 1, "Made test dir ($testdir)");

my $tt2 = Template->new($config);
undef $ret;
$tt2->process(\$data, {}, \$ret);
is($tt2->error(), $expected2, 'Error on PROCESSing directory');

-f "$CACHEDIR/$testdir"
  && fail("Erroneous creation of 0b file with name of folder '$testdir' in cache folder");

rmdir($testdir);

open(my $OUT, '>', $testdir);
close($OUT);

my $tt3 = Template->new($config);
undef $ret;
$tt3->process(\$data, {}, \$ret);
is($ret, $expected3, 'Correctly PROCESSed file');

done_testing();

`rm -rf $CACHEDIR $testdir`;
