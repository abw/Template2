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

__END__


#========================================================================
#                           -- DOCUMENTATION --
#========================================================================

=head1 NAME

Template::Plugins - provider module for loading and instantiating plugins

=head1 SYNOPSIS

    use Template::Plugins;

    $plugin_provider = Template::Plugins->new(\%options);

    ($plugin, $error) = $plugin_provider->fetch($name, @args);

=head1 DESCRIPTION

The Template::Plugins module defines a simple provider which can be used
to load and instantiate Template Toolkit plugin modules.

=head1 METHODS

=head2 new(\%params) 

Constructor method which instantiates and returns a reference to a
Template::Plugins object.  A reference to a hash array of configuration
items may be passed as a parameter.  These are described below.  

Note that the Template.pm front-end module creates a Template::Plugins
provider, passing all configuration items.  Thus, the examples shown
below in the form:

    $plugprov = Template::Plugins->new({
	PLUGIN_BASE => 'MyTemplate::Plugin',
        LOAD_PERL   => 1,
	...
    });

can also be used via the Template module as:

    $ttengine = Template->new({
	PLUGIN_BASE => 'MyTemplate::Plugin',
        LOAD_PERL   => 1,
	...
    });

as well as the more explicit form of:

    $plugprov = Template::Plugins->new({
	PLUGIN_BASE => 'MyTemplate::Plugin',
        LOAD_PERL   => 1,
	...
    });

    $ttengine = Template->new({
	PLUGINS => [ $plugprov ],
	...
    });

=over 4

The configuration options and their meanings are as follows:

=item PLUGIN_BASE

One or more (specified as a list reference) base classes to which plugin
module names should be appended.  The default 'Template::Plugin' is always 
added as the last base.

    $plugprov = Template::Plugins->new({
	PLUGIN_BASE => 'MyTemplate::Plugin',
    });

    # => [ qw( MyTemplate::Plugin Template::Plugin ) ]

    $plugprov = Template::Plugins->new({
	PLUGIN_BASE => [ qw( First::Plugin Second::Plugin ) ],
    });

    # => [ qw( First::Plugin Second::Plugin Template::Plugin ) ]

=item PLUGIN_NAME

Hash array which maps plugin names to correct-case versions.  These are 
added to (and override) the $STD_PLUGINS which, for example, map 
'table' => 'Table', 'cgi' => 'CGI' and so on.  Names are still prepended
by PLUGIN_BASE values.  See the L<BUGS|BUGS> section below for current 
limitations and proposed improvements.

    $plugprov = Template::Plugins->new({
	PLUGIN_NAME => {
	    'myplugin'   => 'MyPlugin',
	    'yourplugin' => 'YourPlugin',
	}
    });
	    

=item PLUGIN_FACTORY

May be provided to pre-initialise the internal hash array which maps
plugin names to factory objects (prototypes) or class names which
should be used to create new plugins.  The factory object/class is
usually determined by calling the load() class method on a module once
(and only once) loaded.  In the simplest case, this returns its own
class name which is then used to call the new() I<class> method.  e.g.

    $package = 'MyPlugin::Foo';
    $factory = $package->load();    # returns 'MyPlugin::Foo'
    $plugin  = $factory->new(...);  # MyPlugin::Foo->new(...)

The load method may also return an object reference (a prototype object).
This is then used to call the new() I<object> method.  e.g.

    $package = 'MyPlugin::Bar';
    $factory = $package->load();    # returns MyPlugin::Bar object
    $plugin  = $factory->new(...);  # method new() called on object

A factory object or class name is determined the first time a module
is loaded (by calling load()), and is then cached for subsequent
re-use.  The PLUGIN_FACTORY hash can provide such factory objects or
class names which will then be used to create new plugins.  Note that
where the entry represents a class name, the relevant module should
already be loaded.

=item LOAD_PERL

Flag to indicate if an attempt should be made to load plugins as regular
Perl modules, i.e. without any PLUGIN_BASE prefix added.

=item TOLERANT

If set true, errors encountered during a fetch() will be downgraded to
declines, returning (undef, STATUS_DECLINED).

=back

=head2 fetch($name, @args)

Called to request that a plugin of a given name be provided.  The relevant 
module is first loaded (if necessary) and the load() class method called 
to return the factory class name (usually the same package name) or a 
factory object (a prototype).  The new() method is then called as a 
class or object method against the factory, passing all remaining
parameters.

Returns a reference to a new plugin object or ($error, STATUS_ERROR)
on error.  May also return (undef, STATUS_DECLINED) to decline to
serve the request.  If TOLERANT is set then all errors will be
returned as declines.

=head1 BUGS / ISSUES

=over 4

=item *

It might be worthwhile being able to distinguish between absolute
module names and those which should be applied relative to PLUGIN_BASE
directories.  For example, use 'MyNamespace::MyModule' to denote
absolute module names (e.g. LOAD_PERL), and 'MyNamespace.MyModule' to
denote relative to PLUGIN_BASE.

=item *

The PLUGIN_NAME facility is a little lame.  As above, names with '::'
could be considered absolute while those containing '.' or no non-word
chars could be relative.  Single name Perl modules (e.g. DBI, CGI,
Template, etc.) might need to be specified as '::DBI', etc., to
distinguish them from the plugins of the same name.  This is ugly, but
may not be necessary if the plugin already exists.  Better suggestions
welcome.  PLUGIN_NAME should work also independantly of LOAD_PERL
(i.e. if an absolute module is named in PLUGIN_NAME then you don't
need LOAD_PERL enabled to load it).  Or can that be implemented as
part of the PLUGIN_FACTORY?

=back

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>
L<Template::Context|Template::Context>

=cut



