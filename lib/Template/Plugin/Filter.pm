#============================================================= -*-Perl-*-
#
# Template::Plugin::Filter
#
# DESCRIPTION
#   Template Toolkit module implementing a base class plugin
#   object which acts like a filter and can be used with the 
#   FILTER directive.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::Filter;

require 5.004;

use strict;
use Template::Plugin;

use base qw( Template::Plugin );
use vars qw( $VERSION $DYNAMIC );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DYNAMIC = 0 unless defined $DYNAMIC;


sub new {
    my ($class, $context, @args) = @_;
    my $config = @args && ref $args[-1] eq 'HASH' ? pop(@args) : { };

    # look for $DYNAMIC
    my $dynamic;
    {
	no strict 'refs';
	$dynamic = ${"$class\::DYNAMIC"};
    }
    $dynamic = $DYNAMIC unless defined $dynamic;

    my $self = bless {
	_CONTEXT => $context,
	_DYNAMIC => $dynamic,
	_ARGS    => \@args,
	_CONFIG  => $config,
    }, $class;

    return $self->init($config)
        || $class->error($self->error());
}


sub init {
    my ($self, $config) = @_;
    return $self;
}


sub factory {
    my $self = shift;

    if ($self->{ _DYNAMIC }) {
	return $self->{ _DYNAMIC_FILTER } ||= [ sub {
	    my ($context, @args) = @_;
	    my $config = ref $args[-1] eq 'HASH' ? pop(@args) : { };
	
	    return sub {
		$self->filter(shift, \@args, $config);
	    };
	}, 1 ];
    }
    else {
	return $self->{ _STATIC_FILTER } ||= sub {
	    $self->filter(shift);
	};
    }
}


sub filter {
    my ($self, $text, $args, $config) = @_;
    return $text;
}


sub merge_config {
    my ($self, $newcfg) = @_;
    my $owncfg = $self->{ _CONFIG };
    return $owncfg unless $newcfg;
    return { %$owncfg, %$newcfg };
}


sub merge_args {
    my ($self, $newargs) = @_;
    my $ownargs = $self->{ _ARGS };
    return $ownargs unless $newargs;
    return [ @$ownargs, @$newargs ];
}


sub install_filter {
    my ($self, $name) = @_;
    $self->{ _CONTEXT }->define_filter( $name => $self->factory() );
    return $self;
}


1;

__END__


