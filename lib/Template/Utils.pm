#============================================================= -*-Perl-*-
#
# Template::Utils
#
# DESCRIPTION
#   Various utility functions for the Template Toolkit.
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

package Template::Utils;

require 5.004;

use strict;
use vars qw( $VERSION );
use Template::Constants;
use File::Basename;
use File::Path;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#========================================================================
#                       ----- PACKAGE SUBS -----
#========================================================================

#------------------------------------------------------------------------
# update_hash(\%target, \%params, \%defaults)
#
# Method called by constructors to update values in the target hash,
# $target, usully representing an object hash.  The second parameter
# should contain a reference to a hash of the intended values.  The 
# optional third parameter may contain a reference to a hash of default
# values.  When specified, the keys of $defaults will be used to extract
# values from $params, using the value of $defaults where it is undefined.
# If $defaults is undefined then all the keys/values of $params will 
# be copied to $target.
#
# Returns the $target reference.
#------------------------------------------------------------------------

sub update_hash {
    my ($target, $params, $defaults) = @_;
    my ($k, $p);

    $defaults = $params 
	unless defined $defaults;

    # look for any valid keys in $params and copy to $target
    foreach $k (keys %$defaults) {
	$p = $params->{ $k };
	$target->{ $k } = defined $p ? $p : $defaults->{ $k };
    }

    $target;
}


#------------------------------------------------------------------------
# output($where, $text)
#------------------------------------------------------------------------

sub output {
    my ($where, $text) = @_;
    my $reftype;
    my $error = 0;
    
    # call a CODE referenc
    if (($reftype = ref($where)) eq 'CODE') {
	&$where($text);
    }
    # print to a glob (such as \*STDOUT)
    elsif ($reftype eq 'GLOB') {
	print $where $text;
    }   
    # append output to a SCALAR ref
    elsif ($reftype eq 'SCALAR') {
	$$where .= $text;
    }
    # call the print() method on an object that implements the method
    # (e.g. IO::Handle, Apache::Request, etc)
    elsif (UNIVERSAL::can($where, 'print')) {
	$where->print($text);
    }
    # a simple string is taken as a filename
    elsif (! $reftype) {
	local *FP;
	# make destination directory if it doesn't exist
	my $dir = dirname($where);
	eval { mkpath($dir) unless -d $dir; };
	if ($@) {
	    # strip file name and line number from error raised by die()
	    ($error = $@) =~ s/ at \S+ line \d+\n?$//;
	}
	elsif (open(FP, ">$where")) { 
	    print FP $text;
	    close FP;
	}
	else {
	    $error  = "$where: $!";
	}
    }
    # give up, we've done our best
    else {
	$error = "output_handler() cannot determine target type ($where)\n";
    }

    return $error;
}



1;

