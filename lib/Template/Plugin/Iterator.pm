#============================================================= -*-Perl-*-
#
# Template::Plugin::Iterator
#
# DESCRIPTION
#
#   Plugin to create a Template::Iterator from a list of items and optional
#   configuration parameters.
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
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Plugin::Iterator;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use Template::Iterator;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

#------------------------------------------------------------------------
# new($context, \@data, \%args)
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    Template::Iterator->new(@_);
}

1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Plugin::Iterator - Plugin to create iterators (Template::Iterator)

=head1 SYNOPSIS

    [% USE iterator(list, args) %]

    [% FOREACH item = iterator %]
       [% '<ul>' IF iterator.first %]
       <li>[% item %]
       [% '</ul>' IF iterator.last %]
    [% END %]

=head1 DESCRIPTION

The iterator plugin provides a way to create a Template::Iterator object 
to iterate over a data set.  An iterator is implicitly automatically by the
FOREACH directive.  This plugin allows the iterator to be explicitly created
with a given name.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.12, distributed as part of the
Template Toolkit version 2.03b, released on 25 June 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Template::Iterator|Template::Iterator>
