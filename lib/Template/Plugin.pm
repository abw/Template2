#============================================================= -*-Perl-*-
#
# Template::Plugin
#
# DESCRIPTION
#
#   Module defining a base class for a plugin object which can be loaded
#   and instantiated via the USE directive.
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

package Template::Plugin;

require 5.004;

use strict;
use Template::Base;

use vars qw( $VERSION $DEBUG $ERROR $AUTOLOAD );
use base qw( Template::Base );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;


#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# load()
#
# Class method called when the plugin module is first loaded.  It 
# returns the name of a class (by default, its own class) or a prototype
# object which will be used to instantiate new objects.  The new() 
# method is then called against the class name (class method) or 
# prototype object (object method) to create a new instances of the 
# object.
#------------------------------------------------------------------------

sub load {
    return $_[0];
}


#------------------------------------------------------------------------
# new($context, $delegate, @params)
#
# Object constructor which is called by the Template::Context to 
# instantiate a new Plugin object.  This base class constructor is 
# used as a general mechanism to load and delegate to other Perl 
# modules.  The context is passed as the first parameter, followed by
# a reference to a delegate object or the name of the module which 
# should be loaded and instantiated.  Any additional parameters passed 
# to the USE directive are forwarded to the new() constructor.
# 
# A plugin object is returned which has an AUTOLOAD method to delegate 
# requests to the underlying object.
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $delclass, @params) = @_;
    my ($delegate, $delmod);

    return $class->error("no context passed to $class constructor\n")
	unless defined $context;

    if (ref $delclass) {
	# $delclass contains a reference to a delegate object
	$delegate = $delclass;
    }
    else {
	# delclass is the name of a module to load and instantiate
	($delmod = $delclass) =~ s|::|/|g;

	eval {
	    require "$delmod.pm";
	    $delegate = $delclass->new(@params)
		|| die "failed to instantiate $delclass object\n";
	};
	return $class->error($@) if $@;
    }

    bless {
	_CONTEXT  => $context, 
	_DELEGATE => $delegate,
	_PARAMS   => \@params,
    }, $class;
}


#------------------------------------------------------------------------
# fail($error)
# 
# Version 1 error reporting function, now replaced by error() inherited
# from Template::Base.  Raises a "deprecated function" warning and then
# calls error().
#------------------------------------------------------------------------

sub fail {
    my $class = shift;
    my ($pkg, $file, $line) = caller();
    warn "Template::Plugin::fail() is deprecated at $file line $line.  Please use error()\n";
    $class->error(@_);
}


#========================================================================
#                      -----  OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# AUTOLOAD
#
# General catch-all method which delegates all calls to the _DELEGATE 
# object.  
#------------------------------------------------------------------------

sub OLD_AUTOLOAD {
    my $self     = shift;
    my $method   = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    if (ref $self eq 'HASH') {
	my $delegate = $self->{ _DELEGATE } || return;
	return $delegate->$method(@_);
    }
    my ($pkg, $file, $line) = caller();
#    warn "no such '$method' method called on $self at $file line $line\n";
    return undef;
}


1;
