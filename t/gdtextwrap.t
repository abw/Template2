#============================================================= -*-perl-*-
#
# t/gdtextwrap.t
#
# Test the GD::Text::Wrap plugin.  Tests are based on the GD::Text
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

eval "use GD; use GD::Text::Wrap;";

if ( $@ ) {
    print "1..0\n";
    exit(0);
}

test_expect(\*DATA);

__END__

-- test --
[% text = BLOCK -%]
Lorem ipsum dolor sit amet, consectetuer adipiscing elit,
sed diam nonummy nibh euismod tincidunt ut laoreet dolore
magna aliquam erat volutpat.
[% END %][%
    USE gd_c = GD.Constants;
    USE gd = GD.Image(170,150);
    x = gd.colorAllocate(255,255,255);
    x = gd.colorAllocate(  0,  0,  0);

    USE wp = GD.Text.Wrap(gd, text => text);
    x = wp.set(align => 'left', width => 130);
    wp.get_bounds(20,10).join(":"); "\n";

    x = wp.set(align => 'justified');
    wp.get_bounds(20,10).join(":"); "\n";

    # Draw, and check that the result is the same
    wp.draw(20,10).join(":"); "\n";

    x = wp.set(align => 'left');
    wp.draw(20,10).join(":"); "\n";

    x = wp.set(align => 'justified');
    wp.draw(20,10).join(":"); "\n";

    x = wp.set(align => 'right');
    wp.draw(20,10).join(":"); "\n";

    x = wp.set(preserve_nl => 1);
    wp.draw(20,10).join(":"); "\n";
-%]
-- expect --
20:10:150:128
20:10:150:128
20:10:150:128
20:10:150:128
20:10:150:128
20:10:150:128
20:10:150:143
