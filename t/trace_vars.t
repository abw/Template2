#!/usr/bin/perl
#
# Perl script to test statis analysis of variables used.
#
# Written by Andy Wardley http://wardley.org/
#
# 31 July 2009
#

use lib qw( ./lib ../lib );
use strict;
use warnings;
use Template;
use Template::Test;

my $tt       = Template->new( TRACE_VARS => 1 );
my $template = $tt->template(\*DATA) || die $tt->error;
my $vars     = $template->variables;

ok( $vars->{ foo }, 'foo is used' );
ok( $vars->{ bar }, 'bar is used' );
ok( $vars->{ bar }->{ baz }, 'bar.baz is used' );
ok( $vars->{ blam }, 'blam is used' );
ok( $vars->{ blam }->{ 0 }, 'blam.0 is used' );
ok( $vars->{ wig }, 'wig is used' );
ok( $vars->{ wig }->{ wam }, 'wig.wam is used' );
ok( $vars->{ wig }->{ wam }->{ bam }, 'wig.wam.bam is used' );

# NOTE: we don't currently detect variables being set, only those being
# fetched...

foreach my $letter ('a'..'e') {
    ok( $vars->{ $letter }, "$letter is used" );
}

# TODO: extend this so we can detect the variables f, g, x and y.z being
# assigned to.

__END__
Hello World 
[% foo -%]
[% bar.baz -%]
[% blam.0 -%]
[% wig(10).wam(a,b,c).bam(f = d, g = e) -%]
[% x = 10; y.z = 20 -%]
Goodbye
