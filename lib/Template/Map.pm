#============================================================= -*-Perl-*-
#
# Template::Map
#
# DESCRIPTION
#   This module implements a generic name to template mapping service.  It 
#   replaces part of the functionality of the experimental Template::View
#   module.
#
# NOTE
#   This is a work-in-progress.  It is not part of the standard TT 
#   distribution and may never be.
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
# REVISION
#   $Id$
#
#============================================================================

package Template::Map;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $AUTOLOAD $MAP $METHOD );
use base qw( Template::Base );

$VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG    = 0 unless defined $DEBUG;
$MAP = {
    HASH    => 'hash',
    ARRAY   => 'list',
    TEXT    => 'text',
    default => '',
};
$METHOD = 'TT_name';

#$DEBUG = 1;    

#------------------------------------------------------------------------
# _init(\%config)
#
# Initialisation method called by the Template::Base class new() 
# constructor.  
#------------------------------------------------------------------------

sub _init {
    my ($self, $config) = @_;

    foreach my $arg (qw( prefix suffix default )) {
	$self->{ $arg } = $config->{ $arg } || '';
    }

    my $format = $config->{ format } || [ ];
    $format = [ $format ] unless ref $format eq 'ARRAY';
    $self->{ format } = $format;

    my $providers = $config->{ provider } || $config->{ providers } || [ ];
    $providers = [ $providers ] unless ref $providers eq 'ARRAY';
    $self->{ providers } = $providers;

    # base?

    return $self;
}


sub map {
    my ($self, $name) = @_;
    my @results;

    # $name can be a ref or object which must first be mapped to a name
    $name = $self->name($name) || return 
	if ref $name;

    # apply each format
    foreach my $format (@{ $self->{ format } }) {
	push(@results, sprintf($format, $name));
    }

    # also add the name with optional prefix/suffix added
    push(@results, "$self->{ prefix }$name$self->{ suffix }");

    # finally add any default option
    push(@results, $self->{ default }) if $self->{ default };

    return \@results;
}


sub name {
    my ($self, $item) = @_;
    my $type = ref $item || return $item;
    my $map  = $MAP;
    my $method = $METHOD;
    my $name;

    return $map->{ $type }
        if defined $map->{ $type };
    
    if ( UNIVERSAL::can($item, $method) ) {
	$self->DEBUG("Calling \$item->$method\n") if $DEBUG;
	$name = $item->$method();
    }   
    else {
	($name = $type) =~ s/\W+/_/g;
    }

    return $name;
}


1;

