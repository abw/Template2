#============================================================= -*-Perl-*-
#
# Template::Iterator
#
# DESCRIPTION
#
#   Module defining an iterator class which is used by the FOREACH
#   directive for iterating through data sets.  This may be
#   sub-classed to define more specific iterator types.
#
#   An iterator is an object which provides a consistent way to
#   navigate through data which may have a complex underlying form.
#   This implementation uses the get_first() and get_next() methods to
#   iterate through a dataset.  The get_first() method is called once
#   to perform any data initialisation and return the first value,
#   then get_next() is called repeatedly to return successive values.
#   Both these methods return a pair of values which are the data item
#   itself and a status code.  The default implementation handles
#   iteration through an array (list) of elements which is passed by
#   reference to the constructor.  An empty list is used if none is
#   passed.  The module may be sub-classed to provide custom
#   implementations which iterate through any kind of data in any
#   manner as long as it can conforms to the get_first()/get_next()
#   interface.  The object also implements the get_all() method for
#   returning all remaining elements as a list reference.
#
#   For further information on iterators see "Design Patterns", by the 
#   "Gang of Four" (Erich Gamma, Richard Helm, Ralph Johnson, John 
#   Vlissides), Addision-Wesley, ISBN 0-201-63361-2.
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

package Template::Iterator;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $AUTOLOAD );    # AUTO?
use base qw( Template::Base );
use Template::Constants;
use Template::Exception;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;


#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\@target, \%options)
#
# Constructor method which creates and returns a reference to a new 
# Template::Iterator object.  A reference to the target data (array
# or hash) may be passed for the object to iterate through.
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $data   = shift || [ ];
    my $params = shift || { };

    if (ref $data eq 'HASH') {
	# map a hash into a list of { key => ???, value => ??? } hashes,
	# one for each key, sorted by keys
	$data = [ map { { key => $_, value => $data->{ $_ } } }
		  sort keys %$data ];
    }
    elsif (UNIVERSAL::can($data, 'as_list')) {
	$data = $data->as_list();
    }
    elsif (ref $data ne 'ARRAY') {
	# coerce any non-list data into an array reference
	$data  = [ $data ] ;
    }

    bless {
	_DATA  => $data,
	_ERROR => '',
    }, $class;
}


#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# get_first()
#
# Initialises the object for iterating through the target data set.  The 
# first record is returned, if defined, along with the STATUS_OK value.
# If there is no target data, or the data is an empty set, then undef 
# is returned with the STATUS_DONE value.  
#------------------------------------------------------------------------

sub get_first {
    my $self  = shift;
    my $data  = $self->{ _DATA };

    $self->{ _DATASET } = $self->{ _DATA };
    my $size = scalar @$data;
    my $index = 0;
    
    return (undef, Template::Constants::STATUS_DONE) unless $size;

    # initialise various counters, flags, etc.
    @$self{ qw( SIZE MAX INDEX COUNT FIRST LAST ) } 
	    = ( $size, $size - 1, $index, 1, 1, $size > 1 ? 0 : 1, undef );
    @$self{ qw( PREV NEXT ) } = ( undef, $self->{ _DATASET }->[ $index + 1 ]);

    return $self->{ _DATASET }->[ $index ];
}



#------------------------------------------------------------------------
# get_next()
#
# Called repeatedly to access successive elements in the data set.
# Should only be called after calling get_first() or a warning will 
# be raised and (undef, STATUS_DONE) returned.
#------------------------------------------------------------------------

sub get_next {
    my $self = shift;
    my ($max, $index) = @$self{ qw( MAX INDEX ) };
    my $data = $self->{ _DATASET };

    # warn about incorrect usage
    unless (defined $index) {
	my ($pack, $file, $line) = caller();
	warn("iterator get_next() called before get_first() at $file line $line\n");
	return (undef, Template::Constants::STATUS_DONE);   ## RETURN ##
    }

    # if there's still some data to go...
    if ($index < $max) {
	# update counters and flags
	$index++;
	@$self{ qw( INDEX COUNT FIRST LAST ) }
	        = ( $index, $index + 1, 0, $index == $max ? 1 : 0 );
	@$self{ qw( PREV NEXT ) } = @$data[ $index - 1, $index + 1 ];
	return $data->[ $index ];			    ## RETURN ##
    }
    else {
	return (undef, Template::Constants::STATUS_DONE);   ## RETURN ##
    }
}


#------------------------------------------------------------------------
# get_all()
#
# Method which returns all remaining items in the iterator as a Perl list
# reference.  May be called at any time in the life-cycle of the iterator.
# The get_first() method will be called automatically if necessary, and
# then subsequent get_next() calls are made, storing each returned 
# result until the list is exhausted.  
#------------------------------------------------------------------------

sub get_all {
    my $self = shift;
    my ($max, $index) = @$self{ qw( MAX INDEX ) };
    my @data;

    # if there's still some data to go...
    if ($index < $max) {
	$index++;
	@data = @{ $self->{ _DATASET } } [ $index..$max ];

	# update counters and flags
	@$self{ qw( INDEX COUNT FIRST LAST ) }
	        = ( $max, $max + 1, 0, 1 );

	return \@data;					    ## RETURN ##
    }
    else {
	return (undef, Template::Constants::STATUS_DONE);   ## RETURN ##
    }
}
    

#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides access to internal fields (e.g. size, first, last, max, etc)
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    # alias NUMBER to COUNT for backwards compatability
    $item = 'COUNT' if $item =~ /NUMBER/i;

    return $self->{ uc $item };
}


#========================================================================
#                   -----  PRIVATE DEBUG METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string detailing the internal state of 
# the iterator object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    join('',
	 "  Data: ", $self->{ _DATA  }, "\n",
	 " Index: ", $self->{ INDEX  }, "\n",
	 "Number: ", $self->{ NUMBER }, "\n",
	 "   Max: ", $self->{ MAX    }, "\n",
	 "  Size: ", $self->{ SIZE   }, "\n",
	 " First: ", $self->{ FIRST  }, "\n",
	 "  Last: ", $self->{ LAST   }, "\n",
	 "\n"
     );
}


1;
