#============================================================= -*-perl-*-
#
# Template::Base
#
# DESCRIPTION
#   Base class module implementing common functionality for various other
#   Template Toolkit modules.
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
#------------------------------------------------------------------------
#
#   $Id$
#
#========================================================================
 
package Template::Base;

require 5.004;

use strict;
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new(\%params)
#
# General purpose constructor method which expects a hash reference of 
# configuration parameters, or a list of name => value pairs which are 
# folded into a hash.  Blesses a hash into an object and calls its 
# _init() method, passing the parameter hash reference.  Returns a new
# object derived from Template::Base, or undef on error.
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my ($argnames, @args, $arg, $cfg);
#    $class->error('');		# always clear package $ERROR var?

    {	no strict qw( refs );
	$argnames = \@{"$class\::BASEARGS"} || [ ];
    }

    # shift off all mandatory args, returning error if undefined or null
    foreach $arg (@$argnames) {
	return $class->error("no $arg specified")
	    unless ($cfg = shift);
	push(@args, $cfg);
    }

    # fold all remaining args into a hash, or use provided hash ref
#    local $" = ', ';
#    print STDERR "args: [@_]\n";
    $cfg  = ref $_[0] eq 'HASH' ? shift : { @_ };

    my $self = bless {
	map { ($_ => shift @args) } @$argnames,
	_ERROR  => ''
    }, $class;

    return $self->_init($cfg) ? $self : $class->error($self->error);
}


#------------------------------------------------------------------------
# error()
# error($msg, ...)
# 
# May be called as a class or object method to set or retrieve the 
# package variable $ERROR (class method) or internal member 
# $self->{ _ERROR } (object method).  The presence of parameters indicates
# that the error value should be set.  Undef is then returned.  In the
# abscence of parameters, the current error value is returned.
#------------------------------------------------------------------------

sub error {
    my $self = shift;
    my $errvar;

    { 
	no strict qw( refs );
	$errvar = ref $self ? \$self->{ _ERROR } : \${"$self\::ERROR"};
    }
    if (@_) {
	$$errvar = ref($_[0]) ? shift : join('', @_);
	return undef;
    }
    else {
	return $$errvar;
    }
}


#------------------------------------------------------------------------
# _init()
#
# Initialisation method called by the new() constructor and passing a 
# reference to a hash array containing any configuration items specified
# as constructor arguments.  Should return $self on success or undef on 
# error, via a call to the error() method to set the error message.
#------------------------------------------------------------------------

sub _init {
    my ($self, $config) = @_;
    return $self;
}


sub DEBUG {
    my $self = shift;
    print STDERR "DEBUG: ", @_;
}

1;

