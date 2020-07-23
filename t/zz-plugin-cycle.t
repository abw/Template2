#============================================================= -*-perl-*-
#
# t/zz-plugin-cycle.t
#
# Check for memory leak when using Template::Plugin::Simple
#
# Written by Nicolas R. <atoomic@cpan.org>
#
# Copyright (C) 2018 cPanel Inc.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( t/lib ./lib ../lib ../blib/arch );

use Template;
use Template::Plugin::Simple;

use Test::More;

plan skip_all => "Developer test" unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} );

eval { require Test::LeakTrace };
if ( $@ or !$INC{'Test/LeakTrace.pm'} ) {
    plan skip_all => 'Test::LeakTrace not installed';
}

plan tests => 2;

note "plugin_simple_test();";

ok plugin_simple_test(), "plugin_simple_test";

note "Searching for leak using Test::LeakTrace...";


my $no_leaks = Test::LeakTrace::no_leaks_ok( \&plugin_simple_test, 'no leak from Template::Plugin' );

if ( !$no_leaks ) {
    diag "Memory leak detected...";

    if ( eval { require Devel::Cycle; 1 } ) {
        Devel::Cycle::find_cycle( plugin_simple_test() );
    }
    else {
        diag "consider installing Devel::Cycle to detect leak";
    }
}

exit;

sub plugin_simple_test {
    my $tpl = Template->new({
        PLUGIN_BASE => [ 'test' ],
        DEBUG => 1,
    }) or die;
    $tpl->context->plugin( 'Simple', [] );

    return $tpl;
}

package test::Simple;

sub new {
    my ($pkg) = @_;
    return bless {}, $pkg;
}

sub load {
    my $class   = shift;
    return $class;
}

1;