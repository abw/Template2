#============================================================= -*-perl-*-
#
# t/zz-plugin-leak.t
#
# Test the Template::Plugins module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2020 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( t/lib ./lib ../lib ../blib/arch );
use Template::Test;
use Template::Plugins;
use Template::Constants qw( :debug );
use Cwd qw( abs_path );
$^W                    = 1;
my $DEBUG = grep(/^--?d(debug)?$/, @ARGV);

BEGIN {
    unless (grep(/--dev/, @ARGV)) {
        skip_all('Internal test for developer, add the --dev flag to run');
    }
    unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
        skip_all("Developer tests not required for installation");
    }
}

use Test::LeakTrace;

if ($@) {
    skip_all('Test::LeakTrace not installed');
}

ntests(2);

my $dir = abs_path(-d 't' ? 't/test/plugin' : 'test/plugin');
my $src = abs_path(-d 't' ? 't/test/lib'    : 'test/lib');
unshift(@INC, $dir);


my ($input, $output);
$output = '';

# Copy input parsing from Template::Test::test_expect
eval {
    local $/ = undef;
    $input = <DATA>;
};

$input =~ s/^#.*?\n//gm;
$input = $' if $input =~ /\s*--\s*start\s*--\s*/;
$input = $` if $input =~ /\s*--\s*stop\s*--\s*/;


# Declare a processor
my $tt1 = Template->new({
    PLUGIN_BASE  => [ 'MyPlugs', 'Template::Plugin' ],
    INCLUDE_PATH => $src,
    DEBUG => $DEBUG ? DEBUG_PLUGINS : 0,
}) || die Template->error();

# Check whether processing with a double-included filter produces more than 4 leaks.
leaks_cmp_ok {
    $tt1->process(\$input, {}, \$output);
} '<', 4;

# There should be none at all here.
no_leaks_ok {
    $tt1->process(\$input, {}, \$output);
} "No leaks at all";

__END__
[% USE Simple -%]
[% 'world' | simple %]
[% INCLUDE simple2 %]
[% 'hello' | simple %]
