#============================================================= -*-Perl-*-
#
# Template::Plugin::CGI
#
# DESCRIPTION
#
#   Simple Template Toolkit plugin interfacing to the CGI.pm module.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Plugin::CGI;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use CGI;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    CGI->new(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::CGI - simple Template Plugin interface to CGI.pm module

=head1 SYNOPSIS

    [% USE CGI %]
    [% CGI.param('parameter') %]

    [% USE things = CGI %]
    [% things.param('name') %]
    
    # see CGI docs for other methods provided by the CGI object

=head1 DESCRIPTION

This is a very simple Template Toolkit Plugin interface to the CGI module.
A CGI object will be instantiated via the following directive:

    [% USE CGI %]

CGI methods may then be called as follows:

    [% CGI.header %]
    [% CGI.param('parameter') %]

An alias can be used to provide an alternate name by which the object should
be identified.

    [% USE mycgi = CGI %]
    [% mycgi.start_form %]
    [% mycgi.popup_menu({ Name   => 'Color'
			  Values => [ 'Green' 'Black' 'Brown' ] }) %]

Parenthesised parameters to the USE directive will be passed to the plugin 
constructor:
    
    [% USE cgiprm = CGI('uid=abw&name=Andy+Wardley') %]
    [% cgiprm.param('uid') %]

=head1 AUTHOR

Andy Wardley E<lt>kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI|CGI>, L<Template::Plugin|Template::Plugin>, 

=cut





