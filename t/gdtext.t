#============================================================= -*-perl-*-
#
# t/gdtext.t
#
# Test the GD::Text plugin.  Tests are based on the GD::Text module tests.
#
# Written by Craig Barratt <craig@arraycomm.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

eval "use GD; use GD::Text;";

if ( $@ || $GD::VERSION < 1.20 ) {
    exit(0);
}

test_expect(\*DATA);

__END__

-- test --
[%
    USE gd_c = GD.Constants;
    USE t = GD.Text;
    x = t.set_text('Some text');
    r = t.get('width', 'height', 'char_up', 'char_down');
    r.join(":"); "\n";

    x = t.set_text('Some other text');
    r.0 = t.get('width');
    r.join(":"); "\n";

    x = t.set_font(gd_c.gdGiantFont);
    t.is_builtin; "\n";

    t.width('Foobar Banana'); "\n";

    t.get('text'); "\n";

    r = t.get('width', 'height', 'char_up', 'char_down');
    r.join(":"); "\n";
-%]
-- expect --
54:13:13:0
90:13:13:0
1
117
Some other text
135:15:15:0
-- test --
[%
    USE gd_c = GD.Constants;
    USE t = GD.Text(text => 'FooBar Banana', font => gd_c.gdGiantFont);
    t.get('width'); "\n";
-%]
-- expect --
117
