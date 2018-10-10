#============================================================= -*-perl-*-
#
# t/mtime-zero.t
#
# Test template process with . in INCLUDE_PATH
#
# Written by Nicolas R. <atoomic@cpan.org>
#
# Copyright (C) 2018 cPanel Inc.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use warnings;

use Template;

use File::Temp qw(tempfile tempdir);

use Test::More tests => 4;

my $content = "hello, world\n";

my ( $tmpfh, $tmpfile ) = tempfile( UNLINK => 1 );
print $tmpfh $content;
close $tmpfh or die $!;

{
    my $out;
    ok( Template->new( { ABSOLUTE => 1 } )->process( $tmpfile, {}, \$out ), "process tmpfile" );
    is( $out, $content, "content as expected" );
}

{
    utime 0, 0, $tmpfile or die $!;

    my $out;
    ok( Template->new( { ABSOLUTE => 1 } )->process( $tmpfile, {}, \$out ), "process tmpfile [utime=0]" );
    is( $out, $content, "content as expected [utime=0]" );
}
