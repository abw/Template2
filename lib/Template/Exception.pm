#============================================================= -*-Perl-*-
#
# Template::Exception
#
# DESCRIPTION
#   Module implementing a generic exception class used for error handling
#   in the Template Toolkit.
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

package Template::Exception;

require 5.004;

use strict;
use vars qw( $VERSION );

use constant TYPE => 0;
use constant INFO => 1;
use constant TEXT => 2;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($type, $info, \$text)
#
# Constructor method used to instantiate a new Template::Exception
# object.  The first parameter should contain the exception type.  This
# can be any arbitrary string of the caller's choice to represent a 
# specific exception.  The second parameter should contain any 
# information (i.e. error message or data reference) relevant to the 
# specific exception event.  The third optional parameter may be a 
# reference to a scalar containing output text from the template 
# block up to the point where the exception was thrown.
#------------------------------------------------------------------------

sub new {
    my ($class, $type, $info, $textref) = @_;
    bless [ $type, $info, $textref ], $class;
}


#------------------------------------------------------------------------
# type()
# info()
# type_info()
#
# Accessor methods to return the internal TYPE and INFO fields.
#------------------------------------------------------------------------

sub type {
    $_[0]->[ TYPE ];
}

sub info {
    $_[0]->[ INFO ];
}

sub type_info {
    my $self = shift;
    @$self[ TYPE, INFO ];
}

#------------------------------------------------------------------------
# text()
# text(\$pretext)
#
# Method to return the text referenced by the TEXT member.  A text 
# reference may be passed as a parameter to supercede the existing 
# member.  The existing text is added to the *end* of the new text
# before being stored.  This facility is provided for template blocks
# to gracefully de-nest when an exception occurs and allows them to 
# reconstruct their output in the correct order. 
#------------------------------------------------------------------------

sub text {
    my ($self, $newtextref) = @_;
    my $textref = $self->[ TEXT ];
    
    if ($newtextref) {
	$$newtextref .= $$textref if $textref && $textref ne $newtextref;
	$self->[ TEXT ] = $newtextref;
	return '';
	
    }
    elsif ($textref) {
	return $$textref;
    }
    else {
	return '';
    }
}


#------------------------------------------------------------------------
# as_string()
#
# Accessor method to return a string indicating the exception type and
# information.
#------------------------------------------------------------------------

sub as_string {
    my $self = shift;
    return $self->[ TYPE ] . ' error - ' . $self->[ INFO ];
}


#------------------------------------------------------------------------
# select_handler(@types)
# 
# Selects the most appropriate handler for the exception TYPE, from 
# the list of types passed in as parameters.  The method returns the
# item which is an exact match for TYPE or the closest, more 
# generic handler (e.g. foo being more generic than foo.bar, etc.)
#------------------------------------------------------------------------

sub select_handler {
    my ($self, @options) = @_;
    my $type = $self->[ TYPE ];
    my %hlut;
    @hlut{ @options } = (1) x @options;

    while ($type) {
	return $type if $hlut{ $type };

	# strip .element from the end of the exception type to find a 
	# more generic handler
	$type =~ s/\.?[^\.]*$//;
    }
    return undef;
}
    
1;

