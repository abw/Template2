#============================================================= -*-Perl-*-
#
# Template::Document
#
# DESCRIPTION
#   Module defining a class of objects which encapsulate compiled
#   templates, storing additional block definitions and metadata 
#   as well as the compiled Perl sub-routine representing the main
#   template content.
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

package Template::Document;

require 5.004;

use strict;
use vars qw( $VERSION $ERROR $COMPERR $DEBUG $AUTOLOAD );
use base qw( Template::Base );
use Template::Constants;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%document)
#
# Creates a new self-contained Template::Document object which 
# encapsulates a compiled Perl sub-routine, $block, any additional 
# BLOCKs defined within the document ($defblocks, also Perl sub-routines)
# and additional $metadata about the document.
#------------------------------------------------------------------------

sub new {
    my ($class, $doc) = @_;
    my ($block, $defblocks, $metadata) = @$doc{ qw( BLOCK DEFBLOCKS METADATA ) };
    $defblocks ||= { };
    $metadata  ||= { };

    # evaluate Perl code in $block to create sub-routine reference if necessary
    unless (ref $block) {
	local $SIG{__WARN__} = \&catch_warnings;
	$COMPERR = '';
	$block = eval $block;
#	$COMPERR .= "[$@]" if $@;
#	return $class->error($COMPERR)
	return $class->error($@)
	    unless defined $block;
    }

    # same for any additional BLOCK definitions
    @$defblocks{ keys %$defblocks } = 
	map { ref($_) ? $_ : (eval($_) or return $class->error($@)) } 
        values %$defblocks;

    bless {
	%$metadata,
	_BLOCK     => $block,
	_DEFBLOCKS => $defblocks,
	_HOT       => 0,
    }, $class;
}


#------------------------------------------------------------------------
# block()
#
# Returns a reference to the internal sub-routine reference, _BLOCK, 
# that constitutes the main document template.
#------------------------------------------------------------------------

sub block {
    return $_[0]->{ _BLOCK };
}


#------------------------------------------------------------------------
# blocks()
#
# Returns a reference to a hash array containing any BLOCK definitions 
# from the template.  The hash keys are the BLOCK nameand the values
# are references to Template::Document objects.  Returns 0 (# an empty hash)
# if no blocks are defined.
#------------------------------------------------------------------------

sub blocks {
    return $_[0]->{ _DEFBLOCKS };
}


#------------------------------------------------------------------------
# process($context)
#
# Process the document in a particular context.  Checks for recursion,
# registers the document with the context via visit(), processes itself,
# and then unwinds with a large gin and tonic.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $defblocks = $self->{ _DEFBLOCKS };
    my $output;


    # check we're not already visiting this template
    return $context->throw(Template::Constants::ERROR_FILE, 
			   "recursion into '$self->{ name }'")
	if $self->{ _HOT } && ! $context->{ RECURSION };   ## RETURN ##

    $context->visit($defblocks);
    $self->{ _HOT } = 1;
    eval {
	my $block = $self->{ _BLOCK };
	$output = &$block($context);
    };
    $self->{ _HOT } = 0;
    $context->leave();

    die $context->catch($@)
	if $@;
	
    return $output;
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides pseudo-methods for read-only access to various internal 
# members. 
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    return $self->{ $method };
}

#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $dblks;
    my $output = "$self : $self->{ name }\n";

    $output .= "BLOCK: $self->{ _BLOCK }\nDEFBLOCKS:\n";

    if ($dblks = $self->{ _DEFBLOCKS }) {
	foreach my $b (keys %$dblks) {
	    $output .= "    $b: $dblks->{ $b }\n";
	}
    }

    return $output;
}


#========================================================================
#                      ----- PACKAGE SUBS -----
#========================================================================

#------------------------------------------------------------------------
# write_perl_file($filename, \%content)
#
# This sub-routine writes the Perl code representing a compiled
# template to a file, specified by name as the first parameter.
# The second parameter should be a hash array containing a main
# template BLOCK, a hash array of additional DEFBLOCKS (named BLOCKs
# definined in the template document source) and a hash array of
# METADATA items.  The values for the BLOCK and individual BLOCKS
# entries should be strings containing Perl code representing the
# templates as compiled by the parser.
#
# Returns 1 on success.  On error, sets the $ERROR package variable
# to contain an error message and returns undef.
#
# This is a bit of an ugly hack.  It might be better if the Document
# object itself had an as_perl() method to return a Perl representation
# of itself.  But that would imply it had to store it's Perl text 
# as well as a reference to the evaluated Perl sub-routines.  Using this
# approach, we can let the new() constructor eval() the Perl code
# and then discard the source text.
#------------------------------------------------------------------------

sub write_perl_file {
    my ($file, $content) = @_;
    my ($block, $defblocks, $metadata) = 
	@$content{ qw( BLOCK DEFBLOCKS METADATA ) };
    my $pkg = __PACKAGE__;

    $defblocks = join('', 
		      map { "'$_' => $defblocks->{ $_ },\n" }
		      keys %$defblocks);

    $metadata = join('', 
		       map { 
			   my $x = $metadata->{ $_ }; 
			   $x =~ s/['\\]/\\$1/g; 
			   "'$_' => '$x',";
		       } keys %$metadata);

    local *CFH;
    open(CFH, ">$file") or do {
	$ERROR = $!;
	return undef;
    };

    print CFH  <<EOF;
bless {
$metadata
_HOT       => 0,
_BLOCK     => $block,
_DEFBLOCKS => {
$defblocks
},
}, $pkg;
EOF
    close(CFH);

    return 1;
}


#------------------------------------------------------------------------
# catch_warnings($msg)
#
# Installed as
#------------------------------------------------------------------------

sub catch_warnings {
    $COMPERR .= join('', @_); 
}

    
1;

