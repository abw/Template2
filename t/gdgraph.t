#============================================================= -*-perl-*-
#
# t/gdgraph.t
#
# Test the GD::Graph::* plugins.  The GD::Graph::* modules don't
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

eval "use GD; use GD::Graph;";

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
    USE g = GD.Graph.lines(300,200);
    x = [1, 2, 3, 4];
    y = [5, 4, 2, 3];
    r = g.set(x_label => 'X Label', y_label => 'Y label', title => 'Title');
    g.plot([x, y]).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
    ];

    USE my_graph = GD.Graph.bars();

    r = my_graph.set(
        x_label         => 'X Label',
        y_label         => 'Y label',
        title           => 'A Simple Bar Chart',
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
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    5,   12,   24,   33,   19,    8,    6,    15,    21],
        [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
    ];

    USE my_graph = GD.Graph.bars();

    r = my_graph.set(
        x_label         => 'X Label',
        y_label         => 'Y label',
        title           => 'Two data sets',

        # shadows
        bar_spacing     => 8,
        shadow_depth    => 4,
        shadowclr       => 'dred',

        long_ticks      => 1,
        y_max_value     => 40,
        y_tick_number   => 8,
        y_label_skip    => 2,
        bar_spacing     => 3,

        accent_treshold => 200,

        transparent     => 0,
    );
    r = my_graph.set_legend( 'Data set 1', 'Data set 2' );
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [50,  52,  53,  54,  55,  56,  57,  58,  59],
        [60,  61,  61,  63,  68,  66,  65,  61, 58],
        [70,  72,  71,  74,  78,  73,  75,  71, 68],
    ];

    USE my_graph = GD.Graph.linespoints;

    r = my_graph.set(
        x_label => 'X Label',
        y_label => 'Y label',
        title => 'A Lines and Points Graph',
        y_max_value => 80,
        y_tick_number => 6,
        y_label_skip => 2,
        y_long_ticks => 1,
        x_tick_length => 2,
        markers => [ 1, 5 ],
        skip_undef => 1,
        transparent => 0,
    );
    r = my_graph.set_legend('data set 1', 'data set 2', 'data set 3');
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    1,    2,    5,    6,    3,  1.5,   -1,    -3,    -4],
        [   -4,   -3,    1,    1,   -3, -1.5,   -2,    -1,     0],
        [    9,    8,    9,  8.4,  7.1,  7.5,    8,     3,    -3],
        [  0.1,  0.2,  0.5,  0.4,  0.3,  0.5,  0.1,     0,   0.4],
        [ -0.1,    2,    5,    4,   -3,  2.5,  3.2,     4,    -4],
    ];

    USE my_graph = GD.Graph.mixed();

    r = my_graph.set(
        types => ['lines', 'lines', 'points', 'area', 'linespoints'],
        default_type => 'points',
    );

    r = my_graph.set(

        x_label         => 'X Label',
        y_label         => 'Y label',
        title           => 'A Mixed Type Graph',

        y_max_value     => 10,
        y_min_value     => -5,
        y_tick_number   => 3,
        y_label_skip    => 0,
        x_plot_values   => 0,
        y_plot_values   => 0,

        long_ticks      => 1,
        x_ticks         => 0,

        legend_marker_width => 24,
        line_width      => 3,
        marker_size     => 5,

        bar_spacing     => 8,

        transparent     => 0,
    );

    r = my_graph.set_legend('one', 'two', 'three', 'four', 'five', 'six');
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

    USE my_graph = GD.Graph.pie( 250, 200 );

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
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    5,   12,   24,   33,   19,    8,    6,    15,    21],
        [   -1,   -2,   -5,   -6,   -3,  1.5,    1,   1.3,     2]
    ];

    USE my_graph = GD.Graph.area();
    r = my_graph.set(
            two_axes => 1,
            zero_axis => 1,
            transparent => 0,
    );
    r = my_graph.set_legend('left axis', 'right axis' );
    my_graph.plot(data).png | head2hex(4, 1);
%]
-- expect --
89504e47
-- test --
[%
    data = [
        ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
        [    5,   12,   24,   33,   19,    8,    6,    15,    21],
        [    1,    2,    5,    6,    3,  1.5,    2,     3,     4],
    ];
    USE my_graph = GD.Graph.points();
    r = my_graph.set(
            x_label => 'X Label',
            y_label => 'Y label',
            title => 'A Points Graph',
            y_max_value => 40,
            y_tick_number => 8,
            y_label_skip => 2,
            legend_placement => 'RC',
            long_ticks => 1,
            marker_size => 6,
            markers => [ 1, 7, 5 ],

            transparent => 0,
    );
    r = my_graph.set_legend('one', 'two');
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

    USE my_graph = GD.Graph.lines();

    r = my_graph.set(
            x_label => 'Month',
            y_label => 'Measure of success',
            title => 'A Simple Line Graph',

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
