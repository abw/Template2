#============================================================= -*-Perl-*-
#
# Template::Plugin::Math
#
# DESCRIPTION
#   Plugin implementing numerous mathematical functions.
#
# AUTHORS
#   Andy Wardley   <abw@kfs.org>
#   ...your name here...
#
# COPYRIGHT
#   Copyright (C) 2002 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::Math;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \%config)
#
# This constructor method creates a simple, empty object to act as a 
# receiver for future object calls.  No doubt there are many interesting
# configuration options that might be passed, but I'll leave that for 
# someone more knowledgable in these areas to contribute...
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $config) = @_;
    $config ||= { };

    bless {
	%$config,
    }, $class;
}


sub sqrt {
    my ($self, $n) = @_;
    return sqrt($n);
}



1;

__END__

=head1 NAME

Template::Plugin::Math - Plugin providing mathematical functions

=head1 SYNOPSIS

    [% USE Math %]

    [% Math.sqrt(9) %]

=head1 DESCRIPTION

The Math plugin provides numerous mathematical functions for use within
templates.

=head1 METHODS

=head2 sqrt($n)

Returns the square root of a number.

=head1 AUTHORS

Andy Wardley E<lt>abw@kfs.orgE<gt> provided the original skeleton plugin 
which was then fleshed out by ...your name here...

=head1 VERSION

This is version 0.01 of the Template::Plugin::Math module.

=head1 COPYRIGHT

  Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>
