#============================================================= -*-Perl-*-
#
# Template::Plugin::View
#
# DESCRIPTION
#   A user-definable view based on templates.  Similar to the concept of
#   a "Skin".
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::View;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use Template::View;

#------------------------------------------------------------------------
# new($context, \%config)
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $context = shift;
    my $view = Template::View->new($context, @_)
	|| return $class->error($Template::View::ERROR);
    $view->seal();
    return $view;
}



1;


__END__

=head1 NAME

Template::Plugin::View - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, 

=cut





