#============================================================= -*-Perl-*-
#
# Template::Plugin::List
#
# DESCRIPTION
#   Template Toolkit plugin to implement an OO List object.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 2001-2006 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::List;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Exception;
use overload q|""| => "text",
             fallback => 1;

our $VERSION = 1.21;
our $ERROR   = '';


local $" = ', ';

#------------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;
    my $context = ref $class ? undef : CORE::shift(@args);
    my $config = @args && ref $args[-1] eq 'HASH' ? CORE::pop(@args) : { };

    $class = ref($class) || $class;

    my $list = defined $config->{ list } 
	? $config->{ list }
        : (scalar @args == 1 && ref $args[0] eq 'ARRAY' ? CORE::shift(@args) 
	   : [ @_ ]);

    print STDERR " list: [ @$list ]\n";
    print STDERR "class: [$class]\n";

    my $joint = defined $config->{ joint } ? $config->{ joint }
                      : $config->{ join  } ? $config->{ join  } 
                      : ', ';

    bless {
	list  => $text,
	joint => $joint,
	_CONTEXT => $context,
    }, $class;
}


sub list {
    return $_[0]->{ list };
}


sub item {
    $_[0]->{ list }->[ $_[1] || 0 ];
}


sub hash {                              ### not sure about this one ###
    my $self = shift; 
    my $n = 0; 
    return { map { ($n++, $_) } @{ $self->{ list } } };
}


sub text {
    my $self = CORE::shift;
    return CORE::join($self->{ joint }, @{ $self->{ list } });
}


sub copy {
    my $self = CORE::shift;
    $self->new($self->{ list });
}


sub throw {
    my $self = CORE::shift;
    die (Template::Exception->new('List', CORE::join('', @_)));
}


#------------------------------------------------------------------------

sub push {
    my $self = CORE::shift;
    CORE::push(@{ $self->{ list } } @_);
    return $self;
}


sub unshift {
    my $self = CORE::shift;
    CORE::unshift(@{ $self->{ list } } @_);
    return $self;
}


sub pop {
    my $self = CORE::shift;
    CORE::pop(@{ $self->{ list } });
    return $self;
}


sub shift {
    my $self = CORE::shift;
    CORE::shift(@{ $self->{ list } });
    return $self;
}


sub max {
    local $^W = 0;
    my $list = $_[0]->{ list };
    return $#$list; 
}


sub size {
    local $^W = 0;
    my $list = $_[0]->{ list };
    return $#$list + 1; 
}

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
        return $list unless $#$list;        # no need to sort 1 item lists
        return $field                       # Schwartzian Transform 
            ?  map  { $_->[0] }             # for case insensitivity
               sort { $a->[1] cmp $b->[1] }
               map  { [ $_, lc $_->{ $field } ] } 
               @$list 
            :  map  { $_->[0] }
               sort { $a->[1] cmp $b->[1] }
               map  { [ $_, lc $_ ] } 
               @$list
   },
   'nsort'    => sub {
        my ($list, $field) = @_;
        return $list unless $#$list;        # no need to sort 1 item lists
        return $field                       # Schwartzian Transform 
            ?  map  { $_->[0] }             # for case insensitivity
               sort { $a->[1] <=> $b->[1] }
               map  { [ $_, lc $_->{ $field } ] } 
               @$list 
            :  map  { $_->[0] }
               sort { $a->[1] <=> $b->[1] }
               map  { [ $_, lc $_ ] } 
               @$list
    },
    defined $LIST_OPS ? %$LIST_OPS : (),


#------------------------------------------------------------------------


#------------------------------------------------------------------------

sub length {
    my $self = CORE::shift;
    return length $self->{ text };
}


sub truncate {
    my ($self, $length, $suffix) = @_;
    return $self unless defined $length;
    $suffix ||= '';
    $self->{ text } = substr($self->{ text }, 0, 
			     $length - CORE::length($suffix)) . $suffix;
    return $self;
}


sub repeat {
    my ($self, $n) = @_;
    return $self unless defined $n;
    $self->{ text } = $self->{ text } x $n;
    return $self;
}


sub replace {
    my ($self, $search, $replace) = @_;
    return $self unless defined $search;
    $replace = '' unless defined $replace;
    $self->{ text } =~ s/$search/$replace/g;
    return $self;
}


sub remove {
    my ($self, $search) = @_;
    $search = '' unless defined $search;
    $self->{ text } =~ s/$search//g;
    return $self;
}


sub split {
    my $self  = CORE::shift;
    my $split = CORE::shift;
    my $limit = CORE::shift || 0;
    $split = '\s+' unless defined $split;
    return [ split($split, $self->{ text }, $limit) ];
}


sub search {
    my ($self, $pattern) = @_;
    return $self->{ text } =~ /$pattern/;
}


sub equals {
    my ($self, $comparison) = @_;
    return $self->{ text } eq $comparison;
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

Template::Plugin::String - Object oriented interface for string manipulation

=head1 SYNOPSIS

    # create String objects via USE directive
    [% USE String %]
    [% USE String 'initial text' %]
    [% USE String text => 'initial text' %]

    # or from an existing String via new()
    [% newstring = String.new %]
    [% newstring = String.new('newstring text') %]
    [% newstring = String.new( text => 'newstring text' ) %]

    # or from an existing String via copy()
    [% newstring = String.copy %]

    # append text to string
    [% String.append('text to append') %]

    # format left, right or center/centre padded
    [% String.left(20) %]
    [% String.right(20) %]
    [% String.center(20) %]   # American spelling
    [% String.centre(20) %]   # European spelling

    # and various other methods...

=head1 DESCRIPTION

This module implements a String class for doing stringy things to
text in an object-oriented way. 

You can create a String object via the USE directive, adding any 
initial text value as an argument or as the named parameter 'text'.

    [% USE String %]
    [% USE String 'initial text' %]
    [% USE String text='initial text' %]

The object created will be referenced as 'String' by default, but you
can provide a different variable name for the object to be assigned
to:

    [% USE greeting = String 'Hello World' %]

Once you've got a String object, you can use it as a prototype to 
create other String objects with the new() method.

    [% USE String %]
    [% greeting = String.new('Hello World') %]

The new() method also accepts an initial text string as an argument
or the named parameter 'text'.

    [% greeting = String.new( text => 'Hello World' ) %]

You can also call copy() to create a new String as a copy of the 
original.

    [% greet2 = greeting.copy %]

The String object has a text() method to return the content of the 
string.

    [% greeting.text %]

However, it is sufficient to simply print the string and let the
overloaded stringification operator call the text() method
automatically for you.

    [% greeting %]

Thus, you can treat String objects pretty much like any regular piece
of text, interpolating it into other strings, for example:

    [% msg = "It printed '$greeting' and then dumped core\n" %]

You also have the benefit of numerous other methods for manipulating
the string.  

    [% msg.append("PS  Don't eat the yellow snow") %]

Note that all methods operate on and mutate the contents of the string
itself.  If you want to operate on a copy of the string then simply
take a copy first:

    [% msg.copy.append("PS  Don't eat the yellow snow") %]

These methods return a reference to the String object itself.  This
allows you to chain multiple methods together.

    [% msg.copy.append('foo').right(72) %]

It also means that in the above examples, the String is returned which
causes the text() method to be called, which results in the new value of
the string being printed.  To suppress printing of the string, you can
use the CALL directive.

    [% foo = String.new('foo') %]

    [% foo.append('bar') %]         # prints "foobar"

    [% CALL foo.append('bar') %]    # nothing

=head1 METHODS

=head2 Construction Methods

The following methods are used to create new String objects.

=over 4

=item new()

Creates a new string using an initial value passed as a positional
argument or the named parameter 'text'.

    [% USE String %]
    [% msg = String.new('Hello World') %]
    [% msg = String.new( text => 'Hello World' ) %]

=item copy()

Creates a new String object which contains a copy of the original string.

    [% msg2 = msg.copy %]

=back

=head2 Inspection Methods

These methods are used to inspect the string content or other parameters
relevant to the string.

=over 4

=item text()

Returns the internal text value of the string.  The stringification
operator is overloaded to call this method.  Thus the following are
equivalent:

    [% msg.text %]
    [% msg %]

=item length()

Returns the length of the string.

    [% USE String("foo") %]

    [% String.length %]   # => 3

=item search($pattern)

Searches the string for the regular expression specified in $pattern
returning true if found or false otherwise.

    [% item = String.new('foo bar baz wiz waz woz') %]

    [% item.search('wiz') ? 'WIZZY! :-)' : 'not wizzy :-(' %]

=item split($pattern, $limit)

Splits the string based on the delimiter $pattern and optional $limit.  
Delegates to Perl's internal split() so the parameters are exactly the same.

    [% FOREACH item.split %]
         ...
    [% END %]

    [% FOREACH item.split('baz|waz') %]
         ...
    [% END %]

=back

=head2 Mutation Methods

These methods modify the internal value of the string.  For example:

    [% USE str=String('foobar') %]

    [% str.append('.html') %]	# str => 'foobar.html'

The value of the String 'str' is now 'foobar.html'.  If you don't want
to modify the string then simply take a copy first.

    [% str.copy.append('.html') %]

These methods all return a reference to the String object itself.  This
has two important benefits.  The first is that when used as above, the 
String object 'str' returned by the append() method will be stringified
with a call to its text() method.  This will return the newly modified 
string content.  In other words, a directive like:

    [% str.append('.html') %]

will update the string and also print the new value.  If you just want
to update the string but not print the new value then use CALL.

    [% CALL str.append('.html') %]

The other benefit of these methods returning a reference to the String
is that you can chain as many different method calls together as you
like.  For example:

    [% String.append('.html').trim.format(href) %]

Here are the methods:

=over 4

=item push($suffix, ...) / append($suffix, ...)

Appends all arguments to the end of the string.  The 
append() method is provided as an alias for push().

    [% msg.push('foo', 'bar') %]
    [% msg.append('foo', 'bar') %]

=item pop($suffix)

Removes the suffix passed as an argument from the end of the String.

    [% USE String 'foo bar' %]
    [% String.pop(' bar')   %]   # => 'foo'

=item unshift($prefix, ...) / prepend($prefix, ...)

Prepends all arguments to the beginning of the string.  The
prepend() method is provided as an alias for unshift().

    [% msg.unshift('foo ', 'bar ') %]
    [% msg.prepend('foo ', 'bar ') %]

=item shift($prefix)

Removes the prefix passed as an argument from the start of the String.

    [% USE String 'foo bar' %]
    [% String.shift('foo ') %]   # => 'bar'

=item left($pad)

If the length of the string is less than $pad then the string is left
formatted and padded with spaces to $pad length.

    [% msg.left(20) %]

=item right($pad)

As per left() but right padding the String to a length of $pad.

    [% msg.right(20) %]

=item center($pad) / centre($pad)

As per left() and right() but formatting the String to be centered within 
a space padded string of length $pad.  The centre() method is provided as 
an alias for center() to keep Yanks and Limeys happy.

    [% msg.center(20) %]    # American spelling
    [% msg.centre(20) %]    # European spelling

=item format($format)

Apply a format in the style of sprintf() to the string.

    [% USE String("world") %]
    [% String.format("Hello %s\n") %]  # => "Hello World\n"

=item upper()

Converts the string to upper case.

    [% USE String("foo") %]

    [% String.upper %]  # => 'FOO'

=item lower()

Converts the string to lower case

    [% USE String("FOO") %]

    [% String.lower %]  # => 'foo'

=item capital()

Converts the first character of the string to upper case.  

    [% USE String("foo") %]

    [% String.capital %]  # => 'Foo'

The remainder of the string is left untouched.  To force the string to
be all lower case with only the first letter capitalised, you can do 
something like this:

    [% USE String("FOO") %]

    [% String.lower.capital %]  # => 'Foo'

=item chop()

Removes the last character from the string.

    [% USE String("foop") %]

    [% String.chop %]	# => 'foo'

=item chomp()

Removes the trailing newline from the string.

    [% USE String("foo\n") %]

    [% String.chomp %]	# => 'foo'

=item trim()

Removes all leading and trailing whitespace from the string

    [% USE String("   foo   \n\n ") %]

    [% String.trim %]	# => 'foo'

=item collapse()

Removes all leading and trailing whitespace and collapses any sequences
of multiple whitespace to a single space.

    [% USE String(" \n\r  \t  foo   \n \n bar  \n") %]

    [% String.collapse %]   # => "foo bar"

=item truncate($length, $suffix)

Truncates the string to $length characters.

    [% USE String('long string') %]
    [% String.truncate(4) %]  # => 'long'

If $suffix is specified then it will be appended to the truncated
string.  In this case, the string will be further shortened by the 
length of the suffix to ensure that the newly constructed string
complete with suffix is exactly $length characters long.

    [% USE msg = String('Hello World') %]
    [% msg.truncate(8, '...') %]   # => 'Hello...'

=item replace($search, $replace)

Replaces all occurences of $search in the string with $replace.

    [% USE String('foo bar foo baz') %]
    [% String.replace('foo', 'wiz')  %]  # => 'wiz bar wiz baz'

=item remove($search)

Remove all occurences of $search in the string.

    [% USE String('foo bar foo baz') %]
    [% String.remove('foo ')  %]  # => 'bar baz'

=item repeat($count)

Repeats the string $count times.

    [% USE String('foo ') %]
    [% String.repeat(3)  %]  # => 'foo foo foo '

=back

=head1 AUTHOR

Andy Wardley E<lt>abw@wardley.orgE<gt>

L<http://wardley.org/>

=head1 VERSION

2.02, distributed as part of the
Template Toolkit version 2.06b, released on 03 December 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>
