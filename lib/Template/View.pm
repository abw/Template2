#============================================================= -*-Perl-*-
#
# Template::View
#
# DESCRIPTION
#   A custom view of a template processing context.  Can be used to 
#   implement custom "skins".
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# TODO
#  * allow 'type' to be specified to print to force type evaluation
#  * promote 'file' errors to 'view' errors?
#  * 'trybare' option
#  * should we map reference types to templates or to methods?  Perhaps
#    Template::View should do the former and Template::Visitor the 
#    latter?
#
# REVISION
#   $Id$
#
#============================================================================

package Template::View;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $AUTOLOAD $MAP );
use base qw( Template::Base );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG = 0 unless defined $DEBUG;
$MAP = {
    HASH    => 'hash',
    ARRAY   => 'list',
    TEXT    => 'text',
    default => 'default',
};
    

#------------------------------------------------------------------------
# new($context, \%config)
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $config) = @_;
    $config ||= { };

    return $class->error('no view context')
	unless $context;

    return $class->error('invalid table parameters, expecting a hash')
	unless ref $config eq 'HASH';

    # generate table mapping types of object that we might be asked 
    # to print() to template names
    my $map = $config->{ map };
    if (ref $map eq 'HASH') {
	$map = {
	    %$MAP,
	    %$map,
	};
    }
    elsif ($map) {
	$map = {
	    default => $map,
	};
    }
    else {
	$map = {
	    %$MAP,
	}
    }
    
    # name presentation method which printed objects might provide
    my $method = $config->{ method };
    $method = 'present' unless defined $method;

    bless {
	_CONTEXT    => $context,
	_ERROR      => '',
	prefix      => $config->{ prefix      } || '',
	suffix      => $config->{ suffix      } || '',
	default     => $config->{ default     } || '',
	notfound    => $config->{ notfound    } || '',
	item        => $config->{ item        } || 'item',
	view_prefix => $config->{ view_prefix } || 'view_',
	view_naked  => defined $config->{ view_naked } 
		             ? $config->{ view_naked } : 1,
	method      => $method,
	map         => $map,
    }, $class;
}


#------------------------------------------------------------------------
# print(@items, ..., \%config)
#
# Prints @items in turn by mapping each to an approriate template using 
# the internal 'map' hash.  May otherwise call a present() method on the
# item, or use default templates, etc.  The final argument may be a 
# reference to a hash array providing local overrides to the internal
# defaults for various items (prefix, suffix, etc.)
#------------------------------------------------------------------------

sub print {
    my $self   = shift;
    my $cfg    = ((scalar @_ > 1) && (ref $_[-1] eq 'HASH')) ? pop(@_) : { };
    my $method = $cfg->{ method } || $self->{ method };
    my $map    = $self->{ map };
    my ($item, $type, $template, $present);

    # merge any additional 'map' entries into the default mapping table
    $map = {
	%$map,
	%{ $cfg->{ map } },
    } if ref $cfg->{ map } eq 'HASH';

    my $output = '';
    
    # print each argument
    foreach $item (@_) {
	if (! ($type = ref $item)) {
	    # non-references are TEXT
	    $type = 'TEXT';
	    $template = $map->{ $type };
	}
	elsif (! defined ($template = $map->{ $type })) {
	    # no specific map entry for object, maybe it implements a 
	    # 'present' (or other) method?
	    if ($method && UNIVERSAL::can($item, $method)) {
		$self->DEBUG("Calling $item->$method\n") if $DEBUG;
		$present = $item->$method($self);	## call item method
		# undef returned indicates error, note that we expect 
		# $item to have called error() on the view
		return unless defined $present;
		$output .= $present;
		next;					## NEXT
	    }
	    elsif (! ($template = $cfg->{ default } || $self->{ default })) {
		# default not defined, so construct template name from type
		($template = $type) =~ s/\W+/_/g;
	    }
	}
	$self->DEBUG("Presenting view '", $template || '', "'\n") if $DEBUG;
	$output .= $self->view($template, { $self->{ item }, $item }, $cfg)
	    if $template;
    }
    return $output;
}


#------------------------------------------------------------------------
# view($template, \%vars, \%cfg)
#
# Present a template, $template, mapped according to the current prefix,
# suffix, default, etc., using $vars as a hash reference to variable 
# definitions and $cfg providing any local overrides to the internal
# defaults (e.g. to use a different suffix just this once, etc.)
#------------------------------------------------------------------------

sub view {
    my ($self, $template, $vars, $cfg) = @_;
    my $context = $self->{ _CONTEXT };
    return $context->throw(Template::Constants::ERROR_VIEW,
			   "no view template specified")
	unless $template;

    $vars = { } unless ref $vars eq 'HASH';
    $cfg  = { } unless ref $cfg eq 'HASH';

    my $notfound = $cfg->{ notfound } || $self->{ notfound };
    my $error;

    $template = $self->template_name($template, $cfg);
    $self->DEBUG("looking for $template\n") if $DEBUG;
    eval { $template = $context->template($template) };
    if (($error = $@) && $notfound) {
	$notfound = $self->template_name($notfound, $cfg);
	$self->DEBUG("not found, looking for $notfound\n") 
	    if $DEBUG;
	eval { $template = $context->template($notfound) };
	return $context->throw(Template::Constants::ERROR_VIEW, $error)
	    if $@;	# return first error
    }
    elsif ($error) {
	$self->DEBUG("no 'notfound'\n") 
	    if $DEBUG;
	return $context->throw(Template::Constants::ERROR_VIEW, $error);
    }

    $vars->{ view } = $self;
    $context->include( $template, $vars );
}


#------------------------------------------------------------------------
# template_name($template)
#
# Returns the name of the specified template with any appropriate prefix
# and/or suffix added.
#------------------------------------------------------------------------

sub template_name {
    my ($self, $template, $cfg) = @_;
    $template = ( defined $cfg->{ prefix } 
			    ? $cfg->{ prefix } : $self->{ prefix } )
		  . $template
		  . ( defined $cfg->{ suffix }
			    ? $cfg->{ suffix } : $self->{ suffix } )
		      if $template;

    $self->DEBUG("template name: $template\n") if $DEBUG;
    return $template;
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Returns/updates public internal data items (i.e. not prefixed '_' or 
# '.') or presents a view if the method matches the view_prefix item,
# e.g. view_foo(...) => view('foo', ...).  If that fails then the 
# entire method name will be used as the name of a template to present
# iff the view_naked parameter is set (default: 0).  Otherwise, a
# 'view' exception is raised reporting the error "no such view member: ?"
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    if ($item =~ /^[\._]/) {
	return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
			    "attempt to view private member: $item");
    }
    elsif (exists $self->{ $item }) {
	$self->DEBUG("accessing item: $item\n") if $DEBUG;
	return @_ ? ($self->{ $item } = shift) : $self->{ $item };
    }
    elsif ($item =~ s/^$self->{ view_prefix }//) {
	$self->DEBUG("returning view($item)\n") if $DEBUG;
	return $self->view($item, @_);
    }
    elsif ($self->{ view_naked }) {
	$self->DEBUG("returning naked view($item)\n") if $DEBUG;
	return $self->view($item, @_);
    }
    else {
	return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
					 "no such view member: $item");
    }
}



1;


__END__

=head1 NAME

Template::View - 

=head1 SYNOPSIS

    [% USE view( prefix     => 'my_', 
		 suffix     => '.tt',
		 notfound   => 'no_such_file' 
		 view_naked => 1 ) %]

    # get/set various options
    prefix: [% view.prefix %]
    [% view.suffix = 'tt2' %]

    # present views mapped to specific templates
    [% view.view( 'header', title => 'The Header Title' ) %]
	    # => [% INCLUDE my_header.tt2 title = 'The Header Title' %]

    [% view.view_header( title => 'The Header Title' ) %]
	    # shorter form of above

    [% view.header( title => 'The Header Title' ) %]
	    # very short form of above (requires view_naked option)

    [% view.no_such_file() %]
	    # => [% INCLUDE no_such_file %]

    # use default mapping to print test, hash, list, etc.
    [% view.print("some text") %]
    [% view.print({ alpha => 'a', bravo => 'b' }) %]
    [% view.print([ 'charlie', 'delta' ]) %]

    # define BLOCKs to present different types (plus current prefix/suffix)
    [% BLOCK my_text.tt2 %]
       Text: [% item %]
    [% END %]

    [% BLOCK my_list.tt2 %]
       list: [% item.join(', ') %]
    [% END %]

    [% BLOCK my_hash.tt2 %]
       hash keys: [% item.keys.sort.join(', ')
    [% END %]

    # print() maps 'My::Object' to 'My_Object'
    [% view.print(myobj) %]

    [% BLOCK my_My_Object.tt2 %]
       [% item.this %], [% item.that %]
    [% END %]

    # update object -> template mapping table
    [% view.map('My::Object' => 'obj') %]

    [% view.print(myobj) %]

    [% BLOCK my_obj.tt2 %]
       [% item.this %], [% item.that %]
    [% END %]

    # change prefix, suffix, item name, etc.
    [% view.print(myobj, item='thing', prefix='', suffix='') %]

    [% BLOCK obj %]
       [% thing.this %], [% thing.that %]
    [% END %]


=head1 DESCRIPTION

=head1 METHODS

=head2 new($context, \%config)

Creates a new Template::View presenting a custom view of the specified 
$context object.

A reference to a hash array of configuration options may be passed as the 
second argument.

=over 4

=item prefix

Prefix added to all template names.

    [% USE view(prefix => 'my_') %]
    [% view.view('foo', a => 20) %]	# => my_foo

=item suffix

Suffix added to all template names.

    [% USE view(suffix => '.tt2') %]
    [% view.view('foo', a => 20) %]	# => foo.tt2

=item map 

Hash array mapping reference types to template names.  The print() 
method uses this to determine which template to use to present any
particular item.  The TEXT, HASH and ARRAY items default to 'test', 
'hash' and 'list' appropriately.

    [% USE view(map => { ARRAY   => 'my_list', 
			 HASH    => 'your_hash',
		         My::Foo => 'my_foo', } ) %]

    [% view.print(some_text) %]		# => text
    [% view.print(a_list) %]		# => my_list
    [% view.print(a_hash) %]		# => your_hash
    [% view.print(a_foo) %]		# => my_foo

    [% BLOCK text %]
       Text: [% item %]
    [% END %]

    [% BLOCK my_list %]
       list: [% item.join(', ') %]
    [% END %]

    [% BLOCK your_hash %]
       hash keys: [% item.keys.sort.join(', ')
    [% END %]

    [% BLOCK my_foo %] 
       Foo: [% item.this %], [% item.that %]
    [% END %]

=item method

Name of a method which objects passed to print() may provide for presenting
themselves to the view.  If a specific map entry can't be found for an 
object reference and it supports the method (default: 'present') then 
the method will be called, passing the view as an argument.  The object 
can then make callbacks against the view to present itself.

    package Foo;

    sub present {
	my ($self, $view) = @_;
	return "a regular view of a Foo\n";
    }

    sub debug {
	my ($self, $view) = @_;
	return "a debug view of a Foo\n";
    }

In a template:

    [% USE view %]
    [% view.print(my_foo_object) %]	# a regular view of a Foo

    [% USE view(method => 'debug') %]
    [% view.print(my_foo_object) %]	# a debug view of a Foo

=item default

Default template to use if no specific map entry is found for an item.

    [% USE view(default => 'my_object') %]

    [% view.print(objref) %]		# => my_object

If no map entry or default is provided then the view will attempt to 
construct a template name from the object class, substituting any 
sequence of non-word characters to single underscores, e.g.

    # 'fubar' is an object of class Foo::Bar
    [% view.print(fubar) %]		# => Foo_Bar

Any current prefix and suffix will be added to both the default template 
name and any name constructed from the object class.

=item notfound

Fallback template to use if any other isn't found.

=item item

Name of the template variable to which the print() method assigns the current
item.  Defaults to 'item'.

    [% USE view %]
    [% BLOCK list %] 
       [% item.join(', ') %] 
    [% END %]
    [% view.print(a_list) %]

    [% USE view(item => 'thing') %]
    [% BLOCK list %] 
       [% thing.join(', ') %] 
    [% END %]
    [% view.print(a_list) %]

=item view_prefix

Prefix of methods which should be mapped to view() by AUTOLOAD.  Defaults
to 'view_'.

    [% USE view %]
    [% view.view_header() %]			# => view('header')

    [% USE view(view_prefix => 'show_me_the_' %]
    [% view.show_me_the_header() %]		# => view('header')

=item view_naked

Flag to indcate if any attempt should be made to map method names to 
template names where they don't match the view_prefix.  Defaults to 0.

    [% USE view(view_naked => 1) %]

    [% view.header() %]			# => view('header')

=head2 print( $obj1, $obj2, ... \%config)

=head2 view( $template, \%vars, \%config );

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, 

=cut





