#============================================================= -*-Perl-*-
#
# Template::Filters
#
# DESCRIPTION
#   Defines filter plugins as used by the FILTER directive.
#
# AUTHORS
#   Andy Wardley <abw@kfs.org>, with a number of filters contributed
#   by Leslie Michael Orchard <deus_x@nijacode.com>
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

package Template::Filters;

require 5.004;

use strict;
use base qw( Template::Base );
use vars qw( $VERSION $DEBUG $STD_FILTERS );
use Template::Constants;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

$STD_FILTERS = {
    # static filters
    'html'       => sub { return \&html_filter },
    'html_para'  => sub { return \&html_paragraph; },
    'html_break' => sub { return \&html_break; },
    'upper'      => sub { return sub { uc $_[0] } },
    'lower'      => sub { return sub { lc $_[0] } },

    # dynamic filters
    'format'     => \&format_filter_factory,
    'truncate'   => \&truncate_filter_factory,
    'repeat'     => \&repeat_filter_factory,
    'replace'    => \&replace_filter_factory,
    'remove'     => sub { replace_filter_factory(shift(@_), '') },
};



#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# fetch($name, \@args)
#------------------------------------------------------------------------

sub fetch {
    my ($self, $name, $args) = @_;
    my ($factory, $filter, $error);

    # retrieve the filter factory
    return (undef, Template::Constants::STATUS_DECLINED)
	unless ($factory = $self->{ FACTORY }->{ $name });

    if (ref $factory eq 'CODE') {
	# call the factory sub-routine
	eval {
	    $filter = &$factory($args ? @$args : ());
	};
	$error = $@;
	$error = "invalid FILTER '$name' (not a CODE ref)"
	    unless ref($filter) eq 'CODE';
    }
    else {
	$error = "invalid FILTER factory for '$name' (not a CODE ref)";
    }

    if ($error) {
	return $self->{ TOLERANT } 
	       ? (undef,  Template::Constants::STATUS_DECLINED) 
	       : ($error, Template::Constants::STATUS_ERROR) ;
    }
    else {
	return $filter;
    }

}


#========================================================================
#                        -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init(\%config)
#
# Private initialisation method.
#------------------------------------------------------------------------

sub _init {
    my ($self, $params) = @_;
    my $filters = $params->{ FILTER_FACTORY } || { };

    $self->{ FACTORY  } = { %$STD_FILTERS, %$filters };
    $self->{ TOLERANT } = $params->{ TOLERANT }  || 0;

    return $self;
}



#------------------------------------------------------------------------
# _dump()
# 
# Debug method - does nothing much atm.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    return "$self\n";
}



#========================================================================
#                    -- DYNAMIC FILTER FACTORIES --
#========================================================================

#------------------------------------------------------------------------
# [% FILTER format(format) %] -> format_filter_factory()
#
# Create a filter to format text according to a printf()-like format
# string.
#------------------------------------------------------------------------

sub format_filter_factory {
    my $format = shift;
    $format = '%s' unless defined $format;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}


#------------------------------------------------------------------------
# [% FILTER repeat(n) %] -> repeat_filter_factory($n)
#
# Create a filter to repeat text n times.
#------------------------------------------------------------------------

sub repeat_filter_factory {
    my $iter = shift;
    $iter = 1 unless defined $iter;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join('\n', $text) x $iter;
    }
}


#------------------------------------------------------------------------
# [% FILTER replace(search, replace) %] -> replace_filter_factory($s, $r)
#
# Create a filter to replace 'search' text with 'replace'
#------------------------------------------------------------------------

sub replace_filter_factory {
    my $search  = shift;
    my $replace = shift || '';

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	$text =~ s/$search/$replace/g;
	return $text;
    }
}


#------------------------------------------------------------------------
# [% FILTER truncate(n) %] -> truncate_filter_factory($n)
#
# Create a filter to truncate text after n characters.
#------------------------------------------------------------------------

sub truncate_filter_factory {
    my $len = shift || 32;
    return '' unless $len > 3;
    
    return sub {
	my $text = shift;
	return $text if length $text < $len;
	return substr($text, 0, $len - 3) . "...";
    }
}


#------------------------------------------------------------------------
# [% FILTER redirect(file) %] -> redirect_filter_factory($context, $file)
#
# Create a filter to redirect the block text to a file.
#
# ** BROKEN **
#------------------------------------------------------------------------

sub redirect_filter_factory_is_broken {
    my ($context, $file) = @_;
    sub {
	my $text = shift;
	my $handler;
#	$handler = $context->redirect(TEMPLATE_OUTPUT, $file);
	$context->output($text);
#	$context->redirect(TEMPLATE_OUTPUT, $handler);
	return '';
    }
}



#========================================================================
#                            -- STATIC FILTERS --
#========================================================================

#------------------------------------------------------------------------
# [% FILTER html %] -> html_filter()
#
# Convert any '<', '>' or '&' characters to the HTML equivalents, '&lt;',
# '&gt;' and '&amp;', respectively.
#------------------------------------------------------------------------

sub html_filter {
    my $text = shift;
    foreach ($text) {
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
    }
    $text;
}


#------------------------------------------------------------------------
# [% FILTER html_para %] -> html_paragraph()
#
# Wrap each paragraph of text (delimited by two or more newlines) in the
# <p>...</p> HTML tags.
#------------------------------------------------------------------------

sub html_paragraph  {
    my $text = shift;
    return "<p>\n" 
           . join("\n</p>\n\n<p>\n", split(/(?:\r?\n){2,}/, $text))
	   . "</p>\n";
}


#------------------------------------------------------------------------
# [% FILTER html_break %] -> html_break()
#
# Wrap each paragraph of text (delimited by two or more newlines) in the
# <p>...</p> HTML tags.
#------------------------------------------------------------------------

sub html_break  {
    my $text = shift;
    $text =~ s/(\r?\n){2,}/$1<br>$1<br>$1/g;
    return $text;
}


1;

