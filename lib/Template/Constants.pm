#============================================================= -*-Perl-*-
#
# Template::Constants.pm
#
# DESCRIPTION
#   Definition of constants for the Template Toolkit.
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
 
package Template::Constants;

require 5.004;
require Exporter;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

@ISA     = qw( Exporter );
$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#========================================================================
#                         ----- EXPORTER -----
#========================================================================

# STATUS constants returned by directives
use constant STATUS_OK       =>   0;      # ok
use constant STATUS_RETURN   =>   1;      # ok, block ended by RETURN
use constant STATUS_STOP     =>   2;      # ok, stoppped by STOP 
use constant STATUS_DONE     =>   3;      # ok, iterator done
use constant STATUS_DECLINED =>   4;      # ok, declined to service request
use constant STATUS_ERROR    => 255;      # error condition

# ERROR constants for indicating exception types
use constant ERROR_RETURN    =>  'return'; # return a status code
use constant ERROR_FILE      =>  'file';   # file error: I/O, parse, recursion
use constant ERROR_VIEW      =>  'view';   # view error
use constant ERROR_UNDEF     =>  'undef';  # undefined variable value used
use constant ERROR_PERL      =>  'perl';   # error in [% PERL %] block
use constant ERROR_FILTER    =>  'filter'; # filter error
use constant ERROR_PLUGIN    =>  'plugin'; # plugin error

# CHOMP constants for PRE_CHOMP and POST_CHOMP
use constant CHOMP_NONE      => 0; # do not remove whitespace
use constant CHOMP_ALL       => 1; # remove whitespace
use constant CHOMP_COLLAPSE  => 2; # collapse whitespace to a single space

my @STATUS   = qw( STATUS_OK STATUS_RETURN STATUS_STOP STATUS_DONE
		   STATUS_DECLINED STATUS_ERROR );
my @ERROR    = qw( ERROR_FILE ERROR_VIEW ERROR_UNDEF ERROR_PERL 
		   ERROR_RETURN ERROR_FILTER ERROR_PLUGIN );
my @CHOMP    = qw( CHOMP_NONE CHOMP_ALL CHOMP_COLLAPSE );
 
@EXPORT_OK   =   ( @STATUS, @ERROR, @CHOMP );
%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'status'   => [ @STATUS    ],
    'error'    => [ @ERROR     ],
    'chomp'    => [ @CHOMP     ],
);


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

Template::Constants - Defines constants for the Template Toolkit

=head1 SYNOPSIS

    use Template::Constants qw( :status :error :all );

=head1 DESCRIPTION

The Template::Constants modules defines, and optionally exports into the
caller's namespace, a number of constants used by the Template package.

Constants may be used by specifying the Template::Constants package 
explicitly:

    use Template::Constants;

    print Template::Constants::STATUS_DECLINED;

Constants may be imported into the caller's namespace by naming them as 
options to the C<use Template::Constants> statement:

    use Template::Constants qw( STATUS_DECLINED );

    print STATUS_DECLINED;

Alternatively, one of the following tagset identifiers may be specified
to import sets of constants; :status, :error, :all.

    use Template::Constants qw( :status );

    print STATUS_DECLINED;

See L<Exporter> for more information on exporting variables.

=head1 EXPORTABLE TAG SETS

The following tag sets and associated constants are defined: 

  :status
    STATUS_OK                 # no problem, continue
    STATUS_RETURN             # ended current block then continue (ok)
    STATUS_STOP               # controlled stop (ok) 
    STATUS_DONE               # iterator is all done (ok)
    STATUS_DECLINED           # provider declined to service request (ok)
    STATUS_ERROR              # general error condition (not ok)

  :error
    ERROR_RETURN              # return a status code (e.g. 'stop')
    ERROR_FILE                # file error: I/O, parse, recursion
    ERROR_UNDEF               # undefined variable value used
    ERROR_PERL                # error in [% PERL %] block

  :chomp                      # for PRE_CHOMP and POST_CHOMP
    CHOMP_NONE                # do not remove whitespace
    CHOMP_ALL                 # remove whitespace
    CHOMP_COLLAPSE            # collapse whitespace to a single space

  :all         All the above constants.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.43, distributed as part of the
Template Toolkit version 2.06f, released on 13 March 2002.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>, L<Exporter|Exporter>