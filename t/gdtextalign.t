#============================================================= -*-perl-*-
#
# t/gdtextalign.t
#
# Test the GD::Text::Align plugin.  Tests are based on the GD::Text
# module tests.
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

eval "use GD; use GD::Text::Align;";

if ( $@ ) {
    print "1..0\n";
    exit(0);
}

test_expect(\*DATA);

__END__

-- test --
[%
    USE gd_c = GD.Constants;
    USE gd = GD.Image(200,200);
    x = gd.colorAllocate(255,255,255);
    x = gd.colorAllocate(0,0,0);
    USE t = GD.Text.Align(gd);
    x = t.set_text('A string');
    t.get('width', 'height', 'char_up', 'char_down').join(":"); "\n";

    x = t.set_align('top', 'left');
    x = t.draw(100,10);
    t.get('x', 'y').join(":"); "\n";

    x = t.set_align('center', 'right');
    x = t.draw(100,10);
    t.get('x', 'y').join(":"); "\n";

    x = t.set_align('bottom','center');
    x = t.draw(100,20);
    t.get('x', 'y').join(":"); "\n";

    x = t.set_font(gd_c.gdGiantFont);
    x = t.set_align('bottom', 'right');
    x = t.draw(100,40);
    t.get('x', 'y').join(":"); "\n";

    x = t.set_align('bottom', 'left');
    t.bounding_box(100,100).join(":"); "\n";
-%]
-- expect --
48:13:13:0
100:10
52:3.5
76:7
28:25
100:100:172:100:172:85:100:85
-- test --
[%
    USE gd_c = GD.Constants;
    USE gd = GD.Image(200,200);
    x = gd.colorAllocate(255,255,255);
    x = gd.colorAllocate(0,0,0);
    USE t = GD.Text.Align(gd,
            valign => 'top',
            halign => 'left',
            text => 'Banana Boat',
            colour => 1,
            font => gd_c.gdGiantFont,
    );
    t.draw(10,10).join(":"); "\n";
%]
-- expect --
10:25:109:25:109:10:10:10
