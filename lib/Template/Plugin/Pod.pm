#==============================================================================
# 
# Template::Plugin::Pod
#
# DESCRIPTION
#  Pod parser and object model.
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

package Template::Plugin::Pod;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use Pod::POM;

#------------------------------------------------------------------------
# new($context, \%config)
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $context = shift;

    Pod::POM->new(@_);
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

Template::Plugin::Pod - Plugin interface to Pod::POM (Pod Object Model)

=head1 SYNOPSIS

    [% USE Pod(podfile) %]

    [% FOREACH head1 = Pod.head1;
	 FOREACH head2 = head1/head2;
	   ...
         END;
       END
    %]

=head1 DESCRIPTION

This plugin is an interface to the Pod::POM module.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.18, distributed as part of the
Template Toolkit version 2.04d, released on 29 August 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Pod::POM|Pod::POM>
