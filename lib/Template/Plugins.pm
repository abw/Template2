#============================================================= -*-Perl-*-
#
# Template::Plugins
#
# DESCRIPTION
#   Plugin provider which handles the loading of plugin modules and 
#   instantiation of plugin objects.
#
# AUTHORS
#   Andy Wardley <abw@kfs.org>
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

package Template::Plugins;

require 5.004;

use strict;
use base qw( Template::Base );
use vars qw( $VERSION $DEBUG $STD_PLUGINS );
use Template::Constants;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

$STD_PLUGINS   = {
    'cgi'      => 'CGI',
    'dbi'      => 'DBI',
    'url'      => 'URL',
    'format'   => 'Format',
    'table'    => 'Table',
    'iterator' => 'Iterator',
    'datafile' => 'Datafile',
};


#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# fetch($name, \@args, $context)
#
# General purpose method for requesting instantiation of a plugin
# object.  The name of the plugin is passed as the first parameter.
# The internal FACTORY lookup table is consulted to retrieve the
# appropriate factory object or class name.  If undefined, the _load()
# method is called to attempt to load the module and return a factory
# class/object which is then cached for subsequent use.  A reference
# to the calling context should be passed as the third parameter.
# This is passed to the _load() class method.  The new() method is
# then called against the factory class name or prototype object to
# instantiate a new plugin object, passing any arguments specified by
# list reference as the second parameter.  e.g. where $factory is the
# class name 'MyClass', the new() method is called as a class method,
# $factory->new(...), equivalent to MyClass->new(...) .  Where
# $factory is a prototype object, the new() method is called as an
# object method, $myobject->new(...).  This latter approach allows
# plugins to act as Singletons, cache shared
# data, etc.  The 
#------------------------------------------------------------------------

sub fetch {
    my ($self, $name, $args, $context) = @_;
    my ($factory, $plugin, $error);

    # NOTE:
    # the $context ref gets passed as the first parameter to all regular
    # plugins, but not to those loaded via LOAD_PERL;  to hack around
    # this until we have a better implementation, we pass the $args
    # reference to _load() and let it unshift the first args in the 
    # LOAD_PERL case

    $args ||= [ ];
    unshift @$args, $context;

    $factory = $self->{ FACTORY }->{ $name } ||= do {
	($factory, $error) = $self->_load($name, $args);
	return ($factory, $error) if $error;			## RETURN
	$factory;
    };

    # call the new() method on the factory object or class name
    eval {
	print STDERR "args: [ @$args ]\n"
	    if $DEBUG;
	$plugin = $factory->new(@$args)
    	    || die "$name plugin: ", $factory->error(), "\n";	## DIE
    };
    if ($error = $@) {
	chomp $error;
	return $self->{ TOLERANT } 
	       ? (undef,  Template::Constants::STATUS_DECLINED)
	       : ($error, Template::Constants::STATUS_ERROR);
    }

    return $plugin;
}



#========================================================================
#                        -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init(\%config)
#
# Private initialisation method.
#------------------------------------------------------------------------

sub _init {
    my ($self, $params) = @_;
    my ($pbase, $pnames) = @$params{ qw( PLUGIN_BASE PLUGIN_NAME ) };

    $pnames ||= { };
    if (ref $pbase ne 'ARRAY') {
	$pbase = $pbase ? [ $pbase ] : [ ];
    }
    push(@$pbase, 'Template::Plugin');

    $self->{ PLUGIN_BASE } = $pbase;
    $self->{ PLUGIN_NAME } = { %$STD_PLUGINS, %$pnames };
    $self->{ FACTORY     } = $params->{ PLUGIN_FACTORY } || { };
    $self->{ TOLERANT    } = $params->{ TOLERANT }  || 0;
    $self->{ LOAD_PERL   } = $params->{ LOAD_PERL } || 0;

    return $self;
}



#------------------------------------------------------------------------
# _load($name, $args)
#
# Private method which attempts to load a plugin module and determine the 
# correct factory name or object by calling the load() class method in
# the loaded module.  The PLUGIN_NAME member is a hash array which maps 
# "standard" plugin names (in lower case) to their correct case module 
# names, along with any user-supplied name mappings.  Any periods in the
# name are converted to '::'.  The method tries to load the relevant 
# Perl module by prepending each of the PLUGIN_BASE values to the name
# and require()ing it.  If successful, the load() package method for 
# the module is called to return a factory name or reference.
# If the LOAD_PERL option is set and the plugin cannot be loaded by 
# the above then a final attempt is made to load the module without 
# any name prefix.  If this succeeds then the factory name defaults 
# to the package name.  Thus modules loaded in this way must support
# the regular new() class constructor method.
#------------------------------------------------------------------------

sub _load {
    my ($self, $name, $args) = @_;
    my ($factory, $module, $base, $pkg, $file, $ok, $error);
    	    
    ($module = $name) =~ s/\./::/g
	unless defined ($module = $self->{ PLUGIN_NAME }->{ $name });

    foreach $base (@{ $self->{ PLUGIN_BASE } }) {
	$pkg = $base . '::' . $module;
	($file = $pkg) =~ s|::|/|g;

	print STDERR "fetch() attempting to load $file.pm\n"
	    if $DEBUG;

	$ok = eval { require "$file.pm" };
	last unless $@;
	
	$error .= "$@\n" 
	    unless ($@ =~ /^Can\'t locate $file\.pm/);
    }

    if ($ok) {
	print STDERR "fetch() attempting to call $pkg->load()\n"
	    if $DEBUG;

	# first item in @$args is context reference, passed to load()
	$factory = eval { $pkg->load($args->[0]) };
	$error   = '';
	if ($@ || ! $factory) {
	    $error = $@ || 'load() returned a false value';
	}
    }
    elsif ($self->{ LOAD_PERL }) {
	($file = $module) =~ s|::|/|g;
	eval { require "$file.pm" };
	if ($@) {
	    $error = $@;
	}
	else {
	    # remove the context reference from the args list - this isn't
	    # a plugin module and won't be expecting it
	    shift(@$args);
	    $factory = $module;
	    $error   = '';
	}
    }

    if ($factory) {
	print STDERR "load($name) => $factory\n"
	    if $DEBUG;
	return $factory;
    }
    elsif ($error) {
	return $self->{ TOLERANT } 
	    ? (undef,  Template::Constants::STATUS_DECLINED) 
	    : ($error, Template::Constants::STATUS_ERROR);
    }
    else {
	return (undef, Template::Constants::STATUS_DECLINED);
    }
}


#------------------------------------------------------------------------
# _dump()
# 
# Debug method which constructs and returns text representing the current
# state of the object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    local $" = ', ';
    my $fkeys = join(", ", keys %{$self->{ FACTORY }});
    my $pnames = $self->{ PLUGIN_NAME };
    $pnames = join(", ", map { "$_ => $pnames->{ $_ }" } keys %$pnames);

    return <<EOF;
$self
PLUGIN_BASE => [ @{ $self->{ PLUGIN_BASE } } ]
PLUGIN_NAME => { $pnames }
FACTORY     => [ $fkeys ]
TOLERANT    => $self->{ TOLERANT }
LOAD_PERL   => $self->{ LOAD_PERL }
EOF
}


1;

