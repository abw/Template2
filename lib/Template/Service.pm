#============================================================= -*-Perl-*-
#
# Template::Service
#
# DESCRIPTION
#   Module implementing a template processing service which wraps a
#   template within PRE_PROCESS and POST_PROCESS templates and offers 
#   ERROR recovery.
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

package Template::Service;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ERROR $AUTOLOAD );
use base qw( Template::Base );
use Template::Base;
use Template::Config;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;


#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# process($template, \%params)
#
# Process a template within a service framework.  A service may encompass
# PRE_PROCESS and POST_PROCESS templates and an ERROR hash which names
# templates to be substituted for the main template document in case of
# error.  Each service invocation begins by resetting the state of the 
# context object via a call to reset().  The AUTO_RESET option may be set 
# to 0 (default: 1) to bypass this step.
#------------------------------------------------------------------------

sub process {
    my ($self, $template, $params) = @_;
    my $context = $self->{ CONTEXT };
    my ($name, $output, $procout, $error);
    $output = '';

    $context->reset()
	if $self->{ AUTO_RESET };

    # pre-request compiled template from context so that we can alias it 
    # in the stash for pre-processed templates to reference
    $template = $context->template($template)
	|| return $self->error($context->error);

    # localise the variable stash with any parameters passed
    # and set the 'template' variable
    $params ||= { };
    $params->{ template } = $template 
	unless ref $template eq 'CODE';
    $context->localise($params);

    SERVICE: {
	# PRE_PROCESS
	eval {
	    foreach $name (@{ $self->{ PRE_PROCESS } }) {
		$output .= $context->process($name);
	    }
	};
	last SERVICE if ($error = $@);

	# PROCESS
	eval {
	    foreach $name (@{ $self->{ PROCESS } || [ $template ] }) {
		$procout .= $context->process($name);
	    }
	};
	if ($error = $@) {
	    last SERVICE
		unless defined ($procout = $self->_recover(\$error));
	}
	$output .= $procout if defined $procout;

	# POST_PROCESS
	eval {
	    foreach $name (@{ $self->{ POST_PROCESS } }) {
		$output .= $context->process($name);
	    }
	};
	last SERVICE if ($error = $@);
    }

    $context->delocalise();

    if ($error) {
#	$error = $error->as_string if ref $error;
	return $self->error($error);
    }

    return $output;
}


#------------------------------------------------------------------------
# context()
# 
# Returns the internal CONTEXT reference.
#------------------------------------------------------------------------

sub context {
    return $_[0]->{ CONTEXT };
}


#========================================================================
#                     -- PRIVATE METHODS --
#========================================================================

sub _init {
    my ($self, $config) = @_;
    my ($item, $data, $context, $block, $blocks);
    my $delim = $config->{ DELIMITER };
    $delim = ':' unless defined $delim;

    # coerce PRE_PROCESS, PROCESS and POST_PROCESS to arrays if necessary, 
    # by splitting on non-word characters
    foreach $item (qw( PRE_PROCESS PROCESS POST_PROCESS )) {
	$data = $config->{ $item };
	next unless defined $data;
	$data = [ split($delim, $data || '') ]
	    unless ref $data eq 'ARRAY';
        $self->{ $item } = $data;
    }
    # unset PROCESS option unless explicitly specified in config
    $self->{ PROCESS } = undef
	unless exists $config->{ PROCESS };
    
    $self->{ ERROR      } = $config->{ ERROR } || $config->{ ERRORS };
    $self->{ AUTO_RESET } = defined $config->{ AUTO_RESET }
			  ? $config->{ AUTO_RESET } : 1;

    $context = $self->{ CONTEXT } = $config->{ CONTEXT }
        || Template::Config->context($config)
	|| return $self->error(Template::Config->error);

    return $self;
}


#------------------------------------------------------------------------
# _recover(\$exception)
#
# Examines the internal ERROR hash array to find a handler suitable 
# for the exception object passed by reference.  Selecting the handler
# is done by delegation to the exception's select_handler() method, 
# passing the set of handler keys as arguments.  A 'default' handler 
# may also be provided.  The handler value represents the name of a 
# template which should be processed. 
#------------------------------------------------------------------------

sub _recover {
    my ($self, $error) = @_;
    my $context = $self->{ CONTEXT };
    my ($hkey, $handler, $output);

    # a 'stop' exception is thrown by [% STOP %] - we return the output
    # buffer stored in the exception object
    return $$error->text()
	if $$error->type() eq 'stop';

    my $handlers = $self->{ ERROR }
        || return undef;					## RETURN

    if (ref $handlers eq 'HASH') {
	if ($hkey = $$error->select_handler(keys %$handlers)) {
	    $handler = $handlers->{ $hkey };
	}
	elsif ($handler = $handlers->{ default }) {
	    # use default handler
	}
	else {
	    return undef;					## RETURN
	}
    }
    else {
	$handler = $handlers;
    }

    $handler = $context->template($handler) || do {
	$$error = $context->error;
	return undef;						## RETURN
    };

    $context->stash->set('error', $$error);
    eval {
	$output .= $context->process($handler);
    };
    if ($@) {
	$$error = $@;
	return undef;						## RETURN
    }

    return $output;
}



#------------------------------------------------------------------------
# _dump()
#
# Debug method which return a string representing the internal object
# state. 
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $context = $self->{ CONTEXT }->_dump();
    $context =~ s/\n/\n    /gm;

    my $error = $self->{ ERROR };
    $error = join('', 
		  "{\n",
		  (map { "    $_ => $error->{ $_ }\n" }
		   keys %$error),
		  "}\n")
	if ref $error;
    
    local $" = ', ';
    return <<EOF;
$self
PRE_PROCESS  => [ @{ $self->{ PRE_PROCESS } } ]
POST_PROCESS => [ @{ $self->{ POST_PROCESS } } ]
ERROR        => $error
CONTEXT      => $context
EOF
}


1;
