#============================================================= -*-perl-*-
# t/object.t
#
# Template script testing code bindings to objects.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Exception;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;


#------------------------------------------------------------------------
# definition of test object class
#------------------------------------------------------------------------

package TestObject;

use vars qw( $AUTOLOAD );

sub new {
    my ($class, $params) = @_;
    $params ||= {};

    bless {
	PARAMS  => $params,
	DAYS    => [ qw( Monday Tuesday Wednesday Thursday 
			 Friday Saturday Sunday ) ],
	DAY     => 0,
    }, $class;
}

sub yesterday {
    my $self = shift;
    return "Love was such an easy game to play...";
}

sub today {
    my $self = shift;
    return "Live for today and die for tomorrow.";
}

sub tomorrow {
    my ($self, $dayno) = @_;
    $dayno = $self->{ DAY }++
        unless defined $dayno;
    $dayno %= 7;
    return $self->{ DAYS }->[$dayno];
}

sub belief {
    my $self = shift;
    my $b = join(' and ', @_);
    $b = '<nothing>' unless length $b;
    return "Oh I believe in $b.";
}

sub concat {
    my $self = shift;
    local $" = ', ';
    $self->{ PARAMS }->{ args } = "ARGS: @_";
}

sub _private {
    my $self = shift;
    die "illegal call to private method _private()\n";
}


sub AUTOLOAD {
    my ($self, @params) = @_;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';

    my $value = $self->{ PARAMS }->{ $name };
    if (ref($value) eq 'CODE') {
	return &$value(@params);
    }
    elsif (@params) {
	return $self->{ PARAMS }->{ $name } = shift @params;
    }
    else {
	return $value;
    }
}


#------------------------------------------------------------------------
# main 
#------------------------------------------------------------------------

package main;

my $objconf = { 
    'a' => 'alpha',
    'b' => 'bravo',
    'w' => 'whisky',
};

my $replace = {
    thing => TestObject->new($objconf),
    %{ callsign() },
};

test_expect(\*DATA, { INTERPOLATE => 1 }, $replace);



#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
# test method calling via autoload to get parameters
[% thing.a %] [% thing.a %]
[% thing.b %]
$thing.w
-- expect --
alpha alpha
bravo
whisky

# ditto to set parameters
-- test --
[% thing.c = thing.b -%]
[% thing.c %]
-- expect --
bravo

-- test --
[% thing.concat = thing.b -%]
[% thing.args %]
-- expect --
ARGS: bravo

-- test --
[% thing.concat(d) = thing.b -%]
[% thing.args %]
-- expect --
ARGS: delta, bravo

-- test --
[% thing.yesterday %]
[% thing.today %]
[% thing.belief(thing.a thing.b thing.w) %]
-- expect --
Love was such an easy game to play...
Live for today and die for tomorrow.
Oh I believe in alpha and bravo and whisky.

-- test --
Yesterday, $thing.yesterday
$thing.today
${thing.belief('yesterday')}
-- expect --
Yesterday, Love was such an easy game to play...
Live for today and die for tomorrow.
Oh I believe in yesterday.

-- test --
[% thing.belief('fish' 'chips') %]
[% thing.belief %]
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
${thing.belief('fish' 'chips')}
$thing.belief
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
[% thing.tomorrow %]
$thing.tomorrow
-- expect --
Monday
Tuesday

-- test --
[% FOREACH [ 1 2 3 4 5 ] %]$thing.tomorrow [% END %].
-- expect --
Wednesday Thursday Friday Saturday Sunday .


-- stop --
#========================================================================
# TODO: test _private and .private members
#========================================================================

#------------------------------------------------------------------------
# test private methods do not get exposed
#------------------------------------------------------------------------
-- test --
[% TRY %]
before[% thing._private %]after
[% CATCH %]
ERROR: [% error.info %]
[% END %]
-- expect --

-- test --
[% TRY %]
[% thing._private = 10 %]
[% CATCH %]
ERROR: [% error.info %]
[% END %]
-- expect --
ERROR: invalid member name '_private'


-- test --
[% TRY %]
[% key = '_private' -%]
[% thing.${key} %]
[% CATCH %]
ERROR: [% error.info %]
[% END %]
-- expect --
ERROR: invalid member name '_private'

-- test --
[% TRY %]
[% key = '.private' -%]
[% thing.${key} = 'foo' %]
[% CATCH %]
ERROR: [% error.info %]
[% END %]
-- expect --
ERROR: invalid member name '.private'

-- test --
[% other.foo %]
[% other.Help %]
-- expect --
bar
Help Yourself

-- test --
[% localise = 10 -%]
[% localise %]
-- expect --
10

