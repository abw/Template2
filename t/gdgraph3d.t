#============================================================= -*-perl-*-
#
# t/gdgraph3d.t
#
# Test the GD::Graph::*3d plugins.  The GD::Graph3d module doesn't
# come with any tests, so we simply verify that each graph type
# produces a PNG output file, but we don't verify the contents.
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

eval "use GD; use GD::Graph; use GD::Graph::bars3d;";

if ( $@ || $GD::VERSION < 1.20 ) {
    exit(0);
}

test_expect(\*DATA, { FILTERS => {
                            head2hex => [\&head2hex_filter_factory, 1],
                        }
                    });

#
# Grab just the first $len bytes of the input, and optionally convert
# to a hex string if $hex is set
#
sub head2hex_filter_factory
{
    my($context, $len, $hex) = @_;

    return sub {
        my $text = shift;
        return $text if length $text < $len;
        $text = substr($text, 0, $len);
        $text =~ s/(.)/sprintf("%02x", ord($1))/eg if ( $hex );
        return $text;
    }
}

__END__

-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
    ];

    USE my_graph = GD::Graph::bars3d();

    r = my_graph.set(
        x_label         => 'X Label',
        y_label         => 'Y label',
        title           => 'A 3d Bar Chart',
        y_max_value     => 8,
        y_tick_number   => 8,
        y_label_skip    => 2,

        # shadows
        bar_spacing     => 8,
        shadow_depth    => 4,
        shadowclr       => 'dred',

        transparent     => 0,
    );
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
                                     "Sep", "Oct", "Nov", "Dec", ],
        [-5, -4, -3, -3, -1,  0,  2,  1,  3,  4,  6,  7],
        [4,   3,  5,  6,  3,1.5, -1, -3, -4, -6, -7, -8],
        [1,   2,  2,  3,  4,  3,  1, -1,  0,  2,  3,  2],
    ];

    USE my_graph = GD::Graph::lines3d();

    r = my_graph.set(
            x_label => 'Month',
            y_label => 'Measure of success',
            title => 'A 3d Line Graph',

            y_max_value => 8,
            y_min_value => -8,
            y_tick_number => 16,
            y_label_skip => 2,
            box_axis => 0,
            line_width => 3,
            zero_axis_only => 1,
            x_label_position => 1,
            y_label_position => 1,

            x_label_skip => 3,
            x_tick_offset => 2,

            transparent => 0,
    );
    r = my_graph.set_legend("Us", "Them", "Others");
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th"],
        [    4,    2,    3,    4,    3,  3.5]
    ];
    
    USE my_graph = GD::Graph::pie( 250, 200 );

    r = my_graph.set(
            title => 'A Pie Chart',
            label => 'Label',
            axislabelclr => 'black',
            pie_height => 36,

            transparent => 0,
    );
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
