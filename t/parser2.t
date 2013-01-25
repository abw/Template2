#============================================================= -*-perl-*-
#
# t/parser.t
#
# Test the Template::Parser module.
#
# Written by Colin Keith <ckeith@cpan.org>
#
# Copyright (C) 2012 Colin Keith. All Rights Reserved
# Copyright (C) 2012 Hagen Software, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( . ../lib );
use Template::Test;
use Template::Config;
use Template::Parser;
$^W = 1;

#$Template::Test::DEBUG = 0;
#$Template::Test::PRESERVE = 1;
#$Template::Stash::DEBUG = 1;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $p = Template::Parser->new();
my $expectedText = 'this is a test';
my($tokens) = $p->split_text(<<EOF);
[%

'$expectedText';
%]
EOF

is($tokens->[0]->[1], '3-4', 'Correctly exclude blank lines preceeding a directive from line number count');

1;
