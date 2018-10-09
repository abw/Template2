#============================================================= -*-perl-*-
#
# t/process-relative.t
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
use lib qw( ./lib ../lib );
use Template;

#use Template::Test;

use Test::More tests => 8;

#$Template::Test::DEBUG = 0;
#$Template::Context::DEBUG = 1;

my $template_file = q[t/test/dir/file1];

plan( skip_all => "File $template_file missing" ) unless -e $template_file;

foreach my $f ( $template_file, "./$template_file" ) {
    note "processing $f with INCLUDE_PATH='.' ; RELATIVE => 1";
    my $out;
    Template->new( { INCLUDE_PATH => ".", RELATIVE => 1 } )->process( $f, undef, \$out );
    is $out => q[This is file 1], "process file $f";
}

foreach my $f ( $template_file, "./$template_file" ) {
    note "processing $f with RELATIVE => 1";
    my $out;
    Template->new( { RELATIVE => 1 } )->process( $f, undef, \$out );
    is $out => q[This is file 1], "process file $f";
}

{
    my $f = $template_file;
    note "processing $f with INCLUDE_PATH='.'";
    my $out;
    Template->new( { INCLUDE_PATH => "." } )->process( $f, undef, \$out );
    is $out => q[This is file 1], "process file $f";
}

{
    my $f = "./$template_file";
    note "processing $f with INCLUDE_PATH='.'";
    my $out;
    Template->new( { INCLUDE_PATH => "." } )->process( $f, undef, \$out );
    is $out => undef, "process file $f fails without setting RELATIVE";
}

{
    my $out;
    my $f = $template_file;
    note "processing $f without INCLUDE_PATH set";
    Template->new()->process( $f, undef, \$out );
    is $out => q[This is file 1], "process file $f";
}

{
    my $out;
    my $f = "./$template_file";
    note "processing $f without INCLUDE_PATH set";
    Template->new()->process( $f, undef, \$out );
    is $out => undef, "process file $f";
}
