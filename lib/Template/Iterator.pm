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
# Template::Iterator object.  A reference to the target data (currently 
# an array, but future implementations may support hashes or other set 
# types) may be passed for the object to iterate through.
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
    elsif (! UNIVERSAL::isa($data, 'ARRAY')) {
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
    @$self{ qw( _MAX _INDEX 
		size max index number 
		first last ) } 
	= ( $size - 1, $index, 
	    $size, $size - 1, $index, 1, 
	    1, $size > 1 ? 0 : 1 );

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
    my ($max, $index) = @$self{ qw( _MAX _INDEX ) };

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
	@$self{ qw( _INDEX index number 
		    first last ) }
	        = ( $index, $index, $index + 1, 
		    0, $index == $max ? 1 : 0 );

	return $self->{ _DATASET }->[ $index ];		    ## RETURN ##
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
    my ($max, $index) = @$self{ qw( _MAX _INDEX ) };
    my @data;

    # if there's still some data to go...
    if ($index < $max) {
	$index++;
	@data = @{ $self->{ _DATASET } } [ $index..$max ];

	# update counters and flags
	@$self{ qw( _INDEX index number first last ) }
	    = ( $max, $max, $max + 1, 0, 1 );

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
    return $self->{ $item };
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
	 "  Data: ", $self->{ _DATA }, "\n",
	 " Index: ", $self->{ _INDEX }, "\n",
	 "Number: ", $self->{'number'}, "\n",
	 "   Max: ", $self->{ _MAX }, "\n",
	 "  Size: ", $self->{'size'}, "\n",
	 " First: ", $self->{'is_first'}, "\n",
	 "  Last: ", $self->{'is_last'}, "\n",
	 "\n"
     );
}


1;

__END__

=head1 NAME

Template::Iterator - Base iterator class used by the FOREACH directive.

=head1 SYNOPSIS

    my $iter = Template::Iterator->new(\@data, \%options);

=head1 DESCRIPTION

The Template::Iterator module defines a generic data iterator for use 
by the FOREACH directive.  

It may be used as the base class for custom iterators.

=head1 PUBLIC METHODS

=head2 new(\@data) 

Constructor method.  A reference to a list of values is passed as the
first parameter and subsequent get_first() and get_next() calls will return
each element.

=head2 get_first()

Returns a ($value, $error) pair for the first item in the iterator set.
The $error returned may be zero or undefined to indicate a valid datum
was successfully returned.  Returns an error of STATUS_DONE if the list 
is empty.

=head2 get_next()

Returns a ($value, $error) pair for the next item in the iterator set.
Returns an error of STATUS_DONE if all items in the list have been 
visited.

=head2 get_all()

Returns a (\@values, $error) pair for all remaining items in the iterator 
set.  Returns an error of STATUS_DONE if all items in the list have been 
visited.

=head2 size(), max(), index(), number(), first(), last()

Return the size of the iteration set, the maximum index number (size - 1),
the current index number (0..max), the iteration number offset from 1
(index + 1, i.e. 1..size), and boolean values indicating if the current
iteration is the first or last in the set, respectively.

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

=cut





