#============================================================= -*-Perl-*-
#
# Template::Stash
#
# DESCRIPTION
#   Definition of an object class which stores and manages access to 
#   variables for the Template Toolkit. 
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

package Template::Stash;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ROOT_OPS $SCALAR_OPS $HASH_OPS $LIST_OPS );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#========================================================================
#                    -- PACKAGE VARIABLES AND SUBS --
#========================================================================

#------------------------------------------------------------------------
# Definitions of various pseudo-methods.  ROOT_OPS are merged into all
# new Template::Stash objects, and are thus default global functions.
# SCALAR_OPS are methods that can be called on a scalar, and ditto 
# respectively for LIST_OPS and HASH_OPS
#------------------------------------------------------------------------

$ROOT_OPS = {
    'inc'  => sub { local $^W = 0; my $item = shift; ++$item }, 
    'dec'  => sub { local $^W = 0; my $item = shift; --$item }, 
};

$SCALAR_OPS = {
    'length'  => sub { length $_[0] },
    'defined' => sub { return 1 },
    'split'   => sub { my $str = shift; [ split(shift, $str, @_) ] },
};

$HASH_OPS = {
    'keys'   => sub { [ keys   %{ $_[0] } ] },
    'values' => sub { [ values %{ $_[0] } ] },
    'each'   => sub { [ each   %{ $_[0] } ] },
};

$LIST_OPS = {
    'max'     => sub { local $^W = 0; my $list = shift; $#$list; },
    'size'    => sub { local $^W = 0; my $list = shift; $#$list + 1; },
    'first'   => sub { my $list = shift; $list->[0] },
    'last'    => sub { my $list = shift; $list->[$#$list] },
    'reverse' => sub { my $list = shift; [ reverse @$list ] },
    'join'    => sub { 
	    my ($list, $joint) = @_; 
	    join(defined $joint ? $joint : ' ', 
		 map { defined $_ ? $_ : '' } @$list) 
	},
    'sort'    => sub {
	my ($list, $field) = @_;
	return $list unless $#$list;	    # no need to sort 1 item lists
	return $field			    # Schwartzian Transform 
	    ?  map  { $_->[0] }		    # for case insensitivity
	       sort { $a->[1] cmp $b->[1] }
	       map  { [ $_, lc $_->{ $field } ] } 
	       @$list 
	    :  map  { $_->[0] }
	       sort { $a->[1] cmp $b->[1] }
	       map  { [ $_, lc $_ ] } 
	       @$list
   },
};


#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%params)
#
# Constructor method which creates a new Template::Stash object.
# An optional hash reference may be passed containing variable 
# definitions that will be used to initialise the stash.
#
# Returns a reference to a newly created Template::Stash.
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $params = ref $_[0] eq 'HASH' ? shift(@_) : { @_ };

    my $self   = {
	global  => { },
	%$params,
	%$ROOT_OPS,
	'_PARENT' => undef,
    };

    bless $self, $class;
}


#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# clone(\%params)
#
# Creates a copy of the current stash object to effect localisation 
# of variables.  The new stash is blessed into the same class as the 
# parent (which may be a derived class) and has a '_PARENT' member added
# which contains a reference to the parent stash that created it
# ($self).  This member is used in a successive declone() method call to
# return the reference to the parent.
# 
# A parameter may be provided which should reference a hash of 
# variable/values which should be defined in the new stash.  The 
# update() method is called to define these new variables in the cloned
# stash.
#
# Returns a reference to a cloned Template::Stash.
#------------------------------------------------------------------------

sub clone {
    my ($self, $params) = @_;
    $params ||= { };

    bless { 
	%$self,			# copy all parent members
	%$params,		# copy all new data
        '_PARENT' => $self,     # link to parent
    }, ref $self;
}

	
#------------------------------------------------------------------------
# declone($export) 
#
# Returns a reference to the PARENT stash.  When called in the following
# manner:
#    $stash = $stash->declone();
# the reference count on the current stash will drop to 0 and be "freed"
# and the caller will be left with a reference to the parent.  This 
# contains the state of the stash before it was cloned.  
#------------------------------------------------------------------------

sub declone {
    my $self = shift;
    $self->{ _PARENT } || $self;
}


#------------------------------------------------------------------------
# get($ident)
# 
# Returns the value for an variable stored in the stash.  The variable
# may be specified as a simple string, e.g. 'foo', or as an array 
# reference representing compound variables.  In the latter case, each
# pair of successive elements in the list represent a node in the 
# compound variable.  The first is the variable name, the second a 
# list reference of arguments or 0 if undefined.  So, the compound 
# variable [% foo.bar('foo').baz %] would be represented as the list
# [ 'foo', 0, 'bar', ['foo'], 'baz', 0 ].  Returns the value of the
# identifier or an empty string if undefined.  Errors are thrown via
# die().
#------------------------------------------------------------------------

sub get {
    my ($self, $ident, $args) = @_;
    my ($root, $result);
    $root = $self;

    if (ref $ident) {
	my $size = $#$ident;

	# if $ident is a list reference, then we evaluate each item in the 
	# identifier against the previous result, using the root stash 
	# ($self) as the first implicit 'result'...

	foreach (my $i = 0; $i < $size; $i += 2) {
	    $result = $self->_dotop($root, @$ident[$i, $i+1]);
	    last unless defined $result;
	    $root = $result;
	}
    }
    else {
	# ...otherwise, $ident is a string and we can call _dotop() once
	$result = $self->_dotop($root, $ident, $args);
    }

    return defined $result ? $result : '';
}


#------------------------------------------------------------------------
# set($ident, $value, $default)
#
# Updates the value for a variable in the stash.  The first parameter
# should be the variable name or array, as per get().  The second 
# parameter should be the intended value for the variable.  The third,
# optional parameter is a flag which may be set to indicate 'default'
# mode.  When set true, the variable will only be updated if it is
# currently undefined or has a false value.  The magical 'IMPORT'
# variable identifier may be used to indicate that $value is a hash
# reference whose values should be imported.  Returns the value set,
# or an empty string if not set (e.g. default mode).  In the case of 
# IMPORT, returns the number of items imported from the hash.
#------------------------------------------------------------------------

sub set {
    my ($self, $ident, $value, $default) = @_;
    my ($root, $result, $error);

    $root = $self;

    ELEMENT: {
	if (ref $ident) {
	    # a compound identifier may contain multiple elements (e.g. 
	    # foo.bar.baz) and we must first resolve all but the last, 
	    # using _dotop() with the $lvalue flag set which will create 
	    # intermediate hashes if necessary...
	    my $size = $#$ident;
	    foreach (my $i = 0; $i < $size - 2; $i += 2) {
		$result = $self->_dotop($root, @$ident[$i, $i+1], 1);
		last ELEMENT unless defined $result;
		$root = $result;
	    }

	    # then we call _assign() to assign the value to the last element
	    $result = $self->_assign($root, @$ident[$size-1, $size], 
				     $value, $default);
	}
	else {
	    # if $ident is a simple variable name then we just call _assign()
	    $result = $self->_assign($root, $ident, 0, $value, $default);
	}
    }

    return defined $result ? $result : '';
}


#------------------------------------------------------------------------
# update(\%params)
#
# Update multiple variables en masse.  No magic is performed.  Simple
# variable names only.
#------------------------------------------------------------------------

sub update {
    my ($self, $params) = @_;
    @$self{ keys %$params } = values %$params;
}


#========================================================================
#                  -----  PRIVATE OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _dotop($root, $item, \@args, $lvalue)
#
# This is the core 'dot' operation method which evaluates elements of 
# variables against their root.  All variables have an implicit root 
# which is the stash object itself (a hash).  Thus, a non-compound 
# variable 'foo' is actually '(stash.)foo', the compound 'foo.bar' is
# '(stash.)foo.bar'.  The first parameter is a reference to the current
# root, initially the stash itself.  The second parameter contains the 
# name of the variable element, e.g. 'foo'.  The third optional
# parameter is a reference to a list of any parenthesised arguments 
# specified for the variable, which are passed to sub-routines, object 
# methods, etc.  The final parameter is an optional flag to indicate 
# if this variable is being evaluated on the left side of an assignment
# (e.g. foo.bar.baz = 10).  When set true, intermediated hashes will 
# be created (e.g. bar) if necessary.  
#
# Returns the result of evaluating the item against the root, having
# performed any variable "magic".  The value returned can then be used
# as the root of the next _dotop() in a compound sequence.  Returns
# undef if the variable is undefined.
#------------------------------------------------------------------------

sub _dotop {
    my ($self, $root, $item, $args, $lvalue) = @_;
    my $rootref = ref $root;
    my ($value, @result);

    $args ||= [ ];
    $lvalue ||= 0;

#    print STDERR "_dotop(root=$root, item=$item, args=[@$args])\n"
#	if $DEBUG;

    # return undef without an error if either side of the dot is unviable
    # or if an attempt is made to access a private member, starting _ or .
    return undef
	unless $root and defined $item and $item !~ /^[\._]/;

    if ($rootref eq __PACKAGE__ || $rootref eq 'HASH') {

	# if $root is a regular HASH or a Template::Stash kinda HASH (the 
	# *real* root of everything).  We first lookup the named key 
	# in the hash, or create an empty hash in its place if undefined
	# and the $lvalue flag is set.  Otherwise, we check the HASH_OPS
	# pseudo-methods table, calling the code if found, or return undef.

	if (defined($value = $root->{ $item })) {
	    return $value unless ref $value eq 'CODE';	    ## RETURN
	    @result = &$value(@$args);			    ## @result
	}
	elsif ($lvalue) {
	    # we create an intermediate hash if this is an lvalue
	    return $root->{ $item } = { };		    ## RETURN
	}
	elsif ($value = $HASH_OPS->{ $item }) {
	    @result = &$value($root);			    ## @result
	}
	else {
	    return undef;				    ## RETURN
	}
    }
    elsif ($rootref eq 'ARRAY') {

	# if root is an ARRAY then we check for a LIST_OPS pseudo-method 
	# (except for l-values for which it doesn't make any sense)
	# or return the numerical index into the array, or undef

	if (($value = $LIST_OPS->{ $item }) && ! $lvalue) {
	    @result = &$value($root, @$args);		    ## @result
	}
	elsif ($item =~ /^\d+$/) {
	    $value = $root->[$item];
	    return $value unless ref $value eq 'CODE';	    ## RETURN
	    @result = &$value(@$args);			    ## @result
	}
	else {
	    return undef;				    ## RETURN
	}
    }

    # NOTE: we do the can-can because UNIVSERAL::isa($something, 'UNIVERSAL')
    # doesn't appear to work with CGI, returning true for the first call
    # and false for all subsequent calls. 

    elsif (UNIVERSAL::can($root, 'can')) {

	# if $root is a blessed reference (i.e. inherits from the 
	# UNIVERSAL object base class) then we call the item as a method.
	# If that fails then we try to fallback on HASH behaviour if 
	# possible.

	eval { @result = $root->$item(@$args); };	    
	    
	if ($@ && UNIVERSAL::isa($root, 'HASH') 
	       && defined($value = $root->{ $item })) {
	    return $value unless ref $value eq 'CODE';	    ## RETURN
	    @result = &$value(@$args);
	}
	elsif ($@) {
	    die $@;					    ## DIE
	}
    }
    elsif (($value = $SCALAR_OPS->{ $item }) && ! $lvalue) {

	# at this point, it doesn't look like we've got a reference to
	# anything we know about, so we try the SCALAR_OPS pseudo-methods
	# table (not l-values)

	@result = &$value($root, @$args);		    ## @result
    }
    else {
	die "don't know how to access [ $root ].$item\n";   ## DIE
    }

    # fold multiple return items into a list unless first item is undef
    if (defined $result[0]) {
	return						    ## RETURN
	    scalar @result > 1 ? [ @result ] : $result[0];
    }
    elsif (defined $result[1]) {
	die $result[1];					    ## DIE
    }
    elsif ($self->{ _DEBUG }) {
	die "$item is undefined\n";			    ## DIE
    }

    return undef;
}


#------------------------------------------------------------------------
# _assign($root, $item, \@args, $value, $default)
#
# Similar to _dotop() above, but assigns a value to the given variable
# instead of simply returning it.  The first three parameters are the
# root item, the item and arguments, as per _dotop(), followed by the 
# value to which the variable should be set and an optional $default
# flag.  If set true, the variable will only be set if currently false
# (undefined/zero)
#------------------------------------------------------------------------

sub _assign {
    my ($self, $root, $item, $args, $value, $default) = @_;
    my $rootref = ref $root;
    my $result;
    $args ||= [ ];
    $default ||= 0;

#    print(STDERR "_assign(root=$root, item=$item, args=[@$args], \n",
#                         "value=$value, default=$default)\n")
#	if $DEBUG;

    # return undef without an error if either side of the dot is unviable
    # or if an attempt is made to update a private member, starting _ or .
    return undef						## RETURN
	unless $root and defined $item and $item !~ /^[\._]/;
    
    if ($rootref eq 'HASH' || $rootref eq __PACKAGE__) {
	if ($item eq 'IMPORT' && UNIVERSAL::isa($value, 'HASH')) {
	    # IMPORT hash entries into root hash
	    @$root{ keys %$value } = values %$value;
	    return scalar keys %$value;				## RETURN
	}
	# if the root is a hash we set the named key
	return ($root->{ $item } = $value)			## RETURN
	    unless $default && $root->{ $item };
    }
    elsif ($rootref eq 'ARRAY' && $item =~ /^\d+$/) {
	# or set a list item by index number
	return ($root->[$item] = $value)			## RETURN
	    unless $default && $root->{ $item };
    }
    elsif (UNIVERSAL::isa($root, 'UNIVERSAL')) {
	# try to call the item as a method of an object
	return $root->$item(@$args, $value);			## RETURN
    }
    else {
	die "don't know how to assign to [$root].[$item]\n";	## DIE
    }

    return undef;
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the object.  The method calls itself recursively to dump sub-hashes.
#------------------------------------------------------------------------

sub _dump {
    my $self   = shift;
    my $indent = shift || 1;
    my $buffer = '    ';
    my $pad    = $buffer x $indent;
    my $text   = '';
    local $" = ', ';

    my ($key, $value);


    return $text . "...excessive recursion, terminating\n"
	if $indent > 32;

    foreach $key (keys %$self) {

	$value = $self->{ $key };
	$value = '<undef>' unless defined $value;

	if (ref($value) eq 'ARRAY') {
	    $value = "$value [@$value]";
	}
	$text .= sprintf("$pad%-8s => $value\n", $key);
	next if $key =~ /^\./;
	if (UNIVERSAL::isa($value, 'HASH')) {
	    $text .= _dump($value, $indent + 1);
	}
    }
    $text;
}


1;
