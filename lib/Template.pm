#============================================================= -*-perl-*-
#
# Template
#
# DESCRIPTION
#   Module implementing a simple, user-oriented front-end to the Template 
#   Toolkit.
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
 
package Template;
use base qw( Template::Base );

require 5.005;

use strict;
use vars qw( $VERSION $AUTOLOAD $ERROR $DEBUG );
use Template::Base;
use Template::Config;
use Template::Provider;  
use Template::Service;
use File::Basename;
use File::Path;
# use Template::Parser;    # autoloaded on demand

## This is the main version number for the Template Toolkit.
## It is extracted by ExtUtils::MakeMaker and inserted in various places.
$VERSION     = '2.00-rc1';
$ERROR       = '';
$DEBUG       = 0;


#------------------------------------------------------------------------
# process($input, \%replace, $output)
#
# Main entry point for the Template Toolkit.  The Template module 
# delegates most of the processing effort to the underlying SERVICE
# object, an instance of the Template::Service class.  
#------------------------------------------------------------------------

sub process {
    my ($self, $template, $vars, $outstream) = @_;
    my ($output, $error);

    $output = $self->{ SERVICE }->process($template, $vars);
    
    if (defined $output) {
	$outstream ||= $self->{ OUTPUT };
	unless (ref $outstream) {
	    my $outpath = $self->{ OUTPUT_PATH };
	    $outstream = "$outpath/$outstream" if $outpath;
	}	

	# send processed template to output stream, checking for error
	return ($self->error($error))
	    if ($error = &_output($outstream, $output));

	return 1;
    }
    else {
	return $self->error($self->{ SERVICE }->error);
    }
}


#------------------------------------------------------------------------
# service()
#
# Returns a reference to the the internal SERVICE object which handles
# all requests for this Template object
#------------------------------------------------------------------------

sub service {
    my $self = shift;
    return $self->{ SERVICE };
}


#------------------------------------------------------------------------
# context()
#
# Returns a reference to the the CONTEXT object withint the SERVICE 
# object.
#------------------------------------------------------------------------

sub context {
    my $self = shift;
    return $self->{ SERVICE }->{ CONTEXT };
}


#========================================================================
#                     -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init(\%config)
#------------------------------------------------------------------------
sub _init {
    my ($self, $config) = @_;

    $self->{ SERVICE } = $config->{ SERVICE }
	|| Template::Config->service($config)
	|| return $self->error(Template::Config->error);

    $self->{ OUTPUT      } = $config->{ OUTPUT } || \*STDOUT;
    $self->{ OUTPUT_PATH } = $config->{ OUTPUT_PATH };

    return $self;
}


#------------------------------------------------------------------------
# _output($where, $text)
#------------------------------------------------------------------------

sub _output {
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

