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
use constant ERROR_UNDEF     =>  'undef';  # undefined variable value used
use constant ERROR_PERL      =>  'perl';   # error in [% PERL %] block
use constant ERROR_FILTER    =>  'filter'; # filter error
use constant ERROR_PLUGIN    =>  'plugin'; # plugin error

my @STATUS   = qw( STATUS_OK STATUS_RETURN STATUS_STOP STATUS_DONE
		   STATUS_DECLINED STATUS_ERROR );
my @ERROR    = qw( ERROR_FILE ERROR_UNDEF ERROR_PERL ERROR_RETURN
		   ERROR_FILTER ERROR_PLUGIN );

@EXPORT_OK   =   ( @STATUS, @ERROR );
%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'status'   => [ @STATUS    ],
    'error'    => [ @ERROR     ],
);


1;

