#============================================================= -*-perl-*-
#
# t/pod.t
#
# Tests the 'Pod' plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
#use lib qw( /home/abw/src/pmod/Pod-POM/lib );
use lib qw( ./lib ../lib );
use Template::Test;
use Carp qw( confess );
$^W = 1;

$Template::Test::DEBUG = 0;
$Template::Test::PRESERVE = 1;
#$Template::View::DEBUG = 1;

my $pod =<<EOF;
=head1 NAME

This is the name.

=head1 SYNOPSIS

This is the synopsis.

=head1 DESCRIPTION

This is the description.

=head2 METHODS

These are the methods.

=head1 AUTHOR

I am the author.
EOF


my $config = {
    INCLUDE_PATH => 'templates:../templates',
    RELATIVE     => 1,
    POST_CHOMP   => 1,
};

my $vars = {
    podsrc => $pod,
};

test_expect(\*DATA, $config, $vars);

__DATA__
-- test --
[%  USE pod;
    pom = pod.parse_text(podsrc);
    THROW pod pod.error UNLESS pom;
    VIEW v prefix='pod/html/';
	BLOCK list; view.print(i) FOREACH i = item; END;
    END;
    v.print(pom);
%]
-- expect --
??
