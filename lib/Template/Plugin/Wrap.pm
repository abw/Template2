#============================================================= -*-Perl-*-
#
# Template::Plugin::Wrap
#
# DESCRIPTION
#   Plugin for wrapping text via the Text::Wrap module.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Plugin::Wrap;

require 5.004;

use strict;
use vars qw( @ISA $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use Text::Wrap;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my ($class, $context, $format) = @_;;
    $context->define_filter('wrap', [ \&wrap_filter_factory => 1 ]);
    return \&tt_wrap;
}

sub tt_wrap {
    my $text  = shift;
    my $width = shift || 72;
    my $itab  = shift || '';
    my $ntab  = shift || '';
    $Text::Wrap::columns = $width;
    Text::Wrap::wrap($itab, $ntab, $text);
}

sub wrap_filter_factory {
    my ($context, @args) = @_;
    return sub {
	my $text = shift;
	tt_wrap($text, @args);
    }
}


1;

__END__

=head1 NAME

Template::Plugin::Wrap - wrap text using the Text::Wrap module.

=head1 SYNOPSIS

    [% USE wrap %]

    # call wrap subroutine
    [% wrap(mytext, width, initial_tab,  subsequent_tab) %]

    # or use wrap FILTER
    [% mytext FILTER wrap(width, initital_tab, subsequent_tab) %]

=head1 DESCRIPTION

This plugin provides an interface to the Text::Wrap module which 
provides simple paragraph formatting.

It defines a 'wrap' subroutine which can be called, passing the input
text and further optional parameters to specify the page width (default:
72), and tab characters for the first and subsequent lines (no defaults).

    [% USE wrap %]

    [% text = BLOCK %]
    First, attach the transmutex multiplier to the cross-wired 
    quantum homogeniser.
    [% END %]

    [% wrap(text, 40, '* ', '  ') %]

Output:

    * First, attach the transmutex
      multiplier to the cross-wired quantum
      homogeniser.

It also registers a 'wrap' filter which accepts the same three optional 
arguments but takes the input text directly via the filter input.

    [% FILTER bullet = wrap(40, '* ', '  ') -%]
    First, attach the transmutex multiplier to the cross-wired quantum
    homogeniser.
    [%- END %]

    [% FILTER bullet -%]
    Then remodulate the shield to match the harmonic frequency, taking 
    care to correct the phase difference.
    [% END %]

Output:

    * First, attach the transmutex
      multiplier to the cross-wired quantum
      homogeniser.

    * Then remodulate the shield to match
      the harmonic frequency, taking 
      care to correct the phase difference.

=head1 AUTHOR

Andy Wardley E<lt>kfs.orgE<gt>

The Text::Wrap module was written by David Muir Sharnoff
E<lt>muir@idiom.comE<gt> with help from Tim Pierce and many
others.

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Text::Wrap|Text::Wrap>

=cut





