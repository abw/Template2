#============================================================= -*-perl-*-
#
# t/outline_line.t
#
# Test the OUTLINE_TAG option reporting incorrect line numbers.
# https://github.com/abw/Template2/issues/295
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 2022 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Test;
use Template::Parser;

$/=undef;
my $text = <DATA>;

my $parser   = Template::Parser->new({ OUTLINE_TAG => '%%' });
my $parsed   = $parser->parse($text, { name => 'test' });
my $template = $parsed->{ BLOCK };
my @lines;

while ($template =~ /#line (\d) "test"/g) {
    push(@lines, $1);
}
is( join(', ', @lines), "1, 2, 3, 4", "lines 1, 2, 3, 4" );

__DATA__
%% line1
%% line2
[% line3 %]
[% line4 %]
