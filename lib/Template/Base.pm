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
    $cfg  = defined $_[0] && UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };

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

Template::Base - Base class module implementing common functionality

=head1 SYNOPSIS

    package Template::MyModule;
    use base qw( Template::Base );

    sub _init {
	my ($self, $config) = @_;
	$self->{ doodah } = $config->{ doodah }
	    || return $self->error("No 'doodah' specified");
	return $self;
    }

=head1 DESCRIPTION

Base class module which implements a constructor and error reporting 
functionality for various Template Toolkit modules.

=head1 PUBLIC METHODS

=head2 new(\%config)

Constructor method which accepts a reference to a hash array or a list 
of C<name =E<gt> value> parameters which are folded into a hash.  The 
_init() method is then called, passing the configuration hash and should
return true/false to indicate success or failure.  A new object reference
is returned, or undef on error.  Any error message raised can be examined
via the error() class method or directly via the package variable ERROR
in the derived class.

    my $module = Template::MyModule->new({ ... })
        || die Template::MyModule->error(), "\n";

    my $module = Template::MyModule->new({ ... })
        || die "constructor error: $Template::MyModule::ERROR\n";

=head2 error($msg)

May be called as an object method to get/set the internal _ERROR member
or as a class method to get/set the $ERROR variable in the derived class's
package.

    my $module = Template::MyModule->new({ ... })
        || die Template::MyModule->error(), "\n";

    $module->do_something() 
	|| die $module->error(), "\n";

When called with parameters (multiple params are concatenated), this
method will set the relevant variable and return undef.  This is most
often used within object methods to report errors to the caller.

    package Template::MyModule;

    ...

    sub foobar {
	my $self = shift;
	...
	return $self->error('some kind of error...')
	    if $some_condition;
	...
    }

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.31, distributed as part of the
Template Toolkit version 2.05b, released on 21 September 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>
