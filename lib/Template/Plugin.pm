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
use vars qw( $VERSION $DEBUG $PLUGIN_NAMES $JOINT $ERROR $AUTOLOAD );


$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;

# this maps standard library plugins to lower case names for convenience
$PLUGIN_NAMES = {
    'format'   => 'Format',
    'cgi'      => 'CGI',
    'dbi'      => 'DBI',
    'url'      => 'URL',
    'table'    => 'Table',
    'datafile' => 'Datafile',
};




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

    return $class->fail("Invalid context passed to $class constructor\n")
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
	return $class->fail($@) if $@;
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
# Report class errors via the $ERROR package variable.
#------------------------------------------------------------------------

sub fail {
    my $class = shift;
    $ERROR = shift;
    return undef;
}


#------------------------------------------------------------------------
# error()
# 
# Return error in the $ERROR package variable, previously set by calling
# fail().
#------------------------------------------------------------------------

sub error {
    $ERROR;
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

sub AUTOLOAD {
    my $self     = shift;
    my $method   = $AUTOLOAD;
    my $delegate = $self->{ _DELEGATE } || return;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    $delegate->$method(@_);
}






1;

__END__

=head1 NAME

Template::Plugin - Base class for Template plugin objects and general object wrapper

=head1 SYNOPSIS

    package Template::Plugin::MyPlugin;
    use base qw( Template::Plugin );
    use MyModule;

    sub new {
        my $class   = shift;
        my $context = shift;
	$class->SUPER::new($context, MyModule->new(@_));
    }

=head1 DESCRIPTION

A "plugin" for the Template Toolkit is simply a Perl module which 
exists in a known package location (e.g. Template::Plugin::*) and 
conforms to a regular standard, allowing it to be loaded and used 
automatically.

The Template::Plugin module defines a base class from which other 
plugin modules can be derived.  A plugin does not have to be derived
from Template::Plugin but should at least conform to its object-oriented
interface.

It is recommended that you create plugins in your own package namespace
to avoid conflict with toolkit plugins.  e.g. 

    package MyOrg::Template::Plugin::FooBar;

Use the PLUGIN_BASE option to specify the namespace that you use.  e.g.

    use Template;
    my $template = Template->new({ 
	PLUGIN_BASE => 'MyOrg::Template::Plugin',
    });

=head1 PLUGIN API

The following methods form the basic interface between the Template
Toolkit and plugin modules.

=over 4

=item load($context)

This method is called by the Template Toolkit when the plugin module
is first loaded.  It is called as a package method and thus implicitly
receives the package name as the first parameter.  A reference to the
Template::Context object loading the plugin is also passed.  The
default behaviour for the load() method is to simply return the class
name.  The calling context then uses this class name to call the new()
package method.

    package MyPlugin;

    sub load {               # called as MyPlugin->load($context)
	my ($class, $context) = @_;
	return $class;       # returns 'MyPlugin'
    }

=item new($context, @params)

This method is called to instantiate a new plugin object for the USE 
directive.  It is called as a package method against the class name 
returned by load().  A reference to the Template::Context object creating
the plugin is passed, along with any additional parameters specified in
the USE directive.

    sub new {                # called as MyPlugin->new($context)
	my ($class, $context, @params) = @_;
	bless {
	    _CONTEXT => $context,
	}, $class;	     # returns blessed MyPlugin object
    }

=item fail($error)

This method is used for reporting errors.  It returns undef.  e.g.

    sub new {
	my ($class, $context, $dsn) = @_;

	return $class->fail('No data source specified')
	    unless $dsn;

	bless {
	    _DSN => $dsn,
	}, $class;
    }

=item error()

This method returns the error as set by the above fail() method.  It is
called by the loading/creating Template::Context object.

=back

=head1 DEEPER MAGIC

The Template::Context object that handles the loading and use of
plugins calls the new(), fail() and error() methods against the
package name returned by the load() method.  In pseudo-code terms,
it might look something like this:

    $class  = MyPlugin->load($context);       # returns 'MyPlugin'

    $object = $class->new($context, @params)  # MyPlugin->new(...)
	|| die $class->error();               # MyPlugin->error()

The load() method may alterately return a blessed reference to an
object instance.  In this case, new(), fail() and error() are then
called as I<object> methods against that prototype instance. 

    package YourPlugin;

    sub load {
        my ($class, $context) = @_;
	bless {
	    _CONTEXT => $context,
	}, $class;
    }

    sub new {
	my ($self, $context, @params) = @_;
	return $self;
    }

In this example, we have implemented a 'Singleton' plugin.  One object 
gets created when load() is called and this simply returns itself for
each call to new().   

Another implementation might require individual objects to be created
for every call to new(), but with each object sharing a reference to
some other object to maintain cached data, database handles, etc.
This pseudo-code example demonstrates the principle.

    package MyServer;

    sub load {
        my ($class, $context) = @_;
	bless {
	    _CONTEXT => $context,
	    _CACHE   => { },
	}, $class;
    }

    sub new {
	my ($self, $context, @params) = @_;
	MyClient->new($self, @params);
    }

    sub add_to_cache   { ... }

    sub get_from_cache { ... }


    package MyClient;

    sub new {
	my ($class, $server, $blah) = @_;
	bless {
	    _SERVER => $server,
	    _BLAH   => $blah,
	}, $class;
    }

    sub get {
	my $self = shift;
	$self->{ _SERVER }->get_from_cache(@_);
    }

    sub put {
	my $self = shift;
	$self->{ _SERVER }->add_to_cache(@_);
    }

When the plugin is loaded, a MyServer instance is created.  The new() 
method is called against this object which instantiates and returns a 
MyClient object, primed to communicate with the creating MyServer.

=head1 Template::Plugin BASE CLASS

The Template::Plugin module implements a base class from which other 
Template Toolkit plugins can be derived.  In addition, it also acts as
a general-purpose wrapper object, providing a delegation service via an
AUTOLOAD method to an underlying object.

A reference to another object should be passed as a parameter (following 
the context reference) to the base class new() constructor.  All methods
then called on the Template::Plugin object will be delegated to the 
underlying object via an AUTOLOAD method.

    package Template::Plugin::MyPlugin;
    use base qw( Template::Plugin );
    use MyModule;

    sub new {
        my $class   = shift;
        my $context = shift;
	$class->SUPER::new($context, MyModule->new(@_));
    }

The name of a Perl module/class may be specified instead of a
reference.  The constructor will attempt to load the module and
instantiate an object via its new() method.  Any additional parameters
passed will be forwarded onto new().

    package Template::Plugin::CGI;
    use base qw( Template::Plugin );

    sub new {
        my $class   = shift;
        my $context = shift;
	$class->SUPER::new($context, 'CGI', @_);
    }

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

L<Template|Template>, 
L<Template::Context|Template::Context>, 
L<Template::Plugin::CGI|Template::Plugin::CGI>

=cut





