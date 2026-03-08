#============================================================= -*-perl-*-
#
# t/while_max_runtime.t
#
# Test that WHILE_MAX is read at runtime, not baked at compile-time
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template;
use Template::Directive;
use File::Temp qw(tempdir);
use Test::More tests => 6;

# Set a low initial WHILE_MAX
$Template::Directive::WHILE_MAX = 10;

my $tt = Template->new();
my $output;

my $tmpl = '[% TRY; WHILE 1; "."; END; CATCH; error.info; END %]';

# Process with WHILE_MAX = 10
$tt->process(\$tmpl, {}, \$output) || die $tt->error;
like($output, qr/^\.{10}WHILE loop terminated/,
    'WHILE stops at 10 iterations when WHILE_MAX is 10');

# Change WHILE_MAX to 20 at runtime — same template engine, no recompilation
$Template::Directive::WHILE_MAX = 20;
$output = '';
$tt->process(\$tmpl, {}, \$output) || die $tt->error;
like($output, qr/^\.{20}WHILE loop terminated/,
    'WHILE stops at 20 iterations after changing WHILE_MAX at runtime');

# Verify the error message also uses the runtime value
like($output, qr/> 20 iterations/,
    'error message reflects runtime WHILE_MAX value');

# Change back to verify it works in both directions
$Template::Directive::WHILE_MAX = 5;
$output = '';
$tt->process(\$tmpl, {}, \$output) || die $tt->error;
like($output, qr/^\.{5}WHILE loop terminated.*> 5 iterations/,
    'WHILE stops at 5 iterations after lowering WHILE_MAX');

# Test with compiled-to-disk templates: WHILE_MAX should be read
# from the package variable at execution time, not from the compiled file
my $srcdir  = tempdir(CLEANUP => 1);
my $compdir = tempdir(CLEANUP => 1);

# Write a template file
open my $fh, '>', "$srcdir/loop.tt" or die "Can't write: $!";
print $fh '[% TRY; WHILE 1; "."; END; CATCH; error.info; END %]';
close $fh;

# Compile with WHILE_MAX = 15
$Template::Directive::WHILE_MAX = 15;
my $tt_comp = Template->new({
    INCLUDE_PATH => $srcdir,
    COMPILE_DIR  => $compdir,
    COMPILE_EXT  => '.ttc',
});
$output = '';
$tt_comp->process('loop.tt', {}, \$output) || die $tt_comp->error;
like($output, qr/^\.{15}WHILE loop terminated.*> 15 iterations/,
    'compiled template respects WHILE_MAX = 15');

# Change WHILE_MAX and re-process the same compiled template
$Template::Directive::WHILE_MAX = 8;
$output = '';
$tt_comp->process('loop.tt', {}, \$output) || die $tt_comp->error;
like($output, qr/^\.{8}WHILE loop terminated.*> 8 iterations/,
    'compiled-to-disk template picks up WHILE_MAX = 8 at runtime');
