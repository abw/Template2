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
use vars qw( $VERSION $DEBUG $FILTERS );
use Template::Constants;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

#------------------------------------------------------------------------
# standard filters, defined in one of the following forms:
#   name =>   \&static_filter
#   name => [ \&subref, $is_dynamic ]
# If the $is_dynamic flag is set then the sub-routine reference 
# is called to create a new filter each time it is requested;  if
# not set, then it is a single, static sub-routine which is returned
# for every filter request for that name.
#------------------------------------------------------------------------

$FILTERS = {
    # static filters 
    'html'       => \&html_filter,
    'html_para'  => \&html_paragraph,
    'html_break' => \&html_break,
    'upper'      => sub { uc $_[0] },
    'lower'      => sub { lc $_[0] },
    'stderr'     => sub { print STDERR @_; return '' },

    # dynamic filters
    'format'     => [ \&format_filter_factory,   1 ],
    'truncate'   => [ \&truncate_filter_factory, 1 ],
    'repeat'     => [ \&repeat_filter_factory,   1 ],
    'replace'    => [ \&replace_filter_factory,  1 ],
    'remove'     => [ \&remove_filter_factory,   1 ],
    'eval'       => [ \&eval_filter_factory,     1 ],
    'evalperl'   => [ \&perl_filter_factory,     1 ],
    'redirect'   => [ \&redirect_filter_factory, 1 ],
};



#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# fetch($name, \@args, $context)
#
# Attempts to instantiate or return a reference to a filter sub-routine 
# named by the first parameter, $name, with additional constructor 
# arguments passed by reference to a list as the second parameter, 
# $args.  A reference to the calling Template::Context object is 
# passed as the third paramter.
#
# Returns a reference to a filter sub-routine or a pair of values
# (undef, STATUS_DECLINED) or ($error, STATUS_ERROR) to decline to
# deliver the filter or to indicate an error.
#------------------------------------------------------------------------

sub fetch {
    my ($self, $name, $args, $context) = @_;
    my ($factory, $is_dynamic, $filter, $error);

    # retrieve the filter factory
    return (undef, Template::Constants::STATUS_DECLINED)
	unless ($factory = $self->{ FILTERS }->{ $name }
			|| $FILTERS->{ $name });

    if (ref $factory eq 'ARRAY') {
	($factory, $is_dynamic) = @$factory;
    }
    else {
	$is_dynamic = 0;
    }

    if (ref $factory eq 'CODE') {
	if ($is_dynamic) {
	    # if the dynamic flag is set then the sub-routine is a 
	    # factory which should be called to create the actual 
	    # filter...
	    eval {
		($filter, $error) = &$factory($context, $args ? @$args : ());
	    };
	    $error ||= $@;
	    $error = "invalid FILTER for '$name' (not a CODE ref)"
		unless $error || ref($filter) eq 'CODE';
	}
	else {
	    # ...otherwise, it's a static filter sub-routine
	    $filter = $factory;
	}
    }
    else {
	$error = "invalid FILTER entry for '$name' (not a CODE ref)";
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

    $self->{ FILTERS  } = $params->{ FILTERS } || { };
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
#                         -- STATIC FILTER SUBS --
#========================================================================

#------------------------------------------------------------------------
# html_filter()                                         [% FILTER html %]
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
# html_paragraph()                                 [% FILTER html_para %]
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
# html_break()                                    [% FILTER html_break %]
#
# Wrap each paragraph of text (delimited by two or more newlines) in the
# <p>...</p> HTML tags.
#------------------------------------------------------------------------

sub html_break  {
    my $text = shift;
    $text =~ s/(\r?\n){2,}/$1<br>$1<br>$1/g;
    return $text;
}



#========================================================================
#                    -- DYNAMIC FILTER FACTORIES --
#========================================================================

#------------------------------------------------------------------------
# format_filter_factory()                     [% FILTER format(format) %]
#
# Create a filter to format text according to a printf()-like format
# string.
#------------------------------------------------------------------------

sub format_filter_factory {
    my ($context, $format) = @_;
    $format = '%s' unless defined $format;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}


#------------------------------------------------------------------------
# repeat_filter_factory($n)                        [% FILTER repeat(n) %]
#
# Create a filter to repeat text n times.
#------------------------------------------------------------------------

sub repeat_filter_factory {
    my ($context, $iter) = @_;
    $iter = 1 unless defined $iter;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join('\n', $text) x $iter;
    }
}


#------------------------------------------------------------------------
# replace_filter_factory($s, $r)    [% FILTER replace(search, replace) %]
#
# Create a filter to replace 'search' text with 'replace'
#------------------------------------------------------------------------

sub replace_filter_factory {
    my ($context, $search, $replace) = @_;
    $replace = '' unless defined $replace;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	$text =~ s/$search/$replace/g;
	return $text;
    }
}


#------------------------------------------------------------------------
# remove_filter_factory($text)                  [% FILTER remove(text) %]
#
# Create a filter to remove 'search' string from the input text.
#------------------------------------------------------------------------

sub remove_filter_factory {
    my ($context, $search) = @_;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	$text =~ s/$search//g;
	return $text;
    }
}


#------------------------------------------------------------------------
# truncate_filter_factory($n)                    [% FILTER truncate(n) %]
#
# Create a filter to truncate text after n characters.
#------------------------------------------------------------------------

sub truncate_filter_factory {
    my ($context, $len) = @_;
    $len = 32 unless defined $len;

    return sub {
	my $text = shift;
	return $text if length $text < $len;
	return substr($text, 0, $len - 3) . "...";
    }
}


#------------------------------------------------------------------------
# eval_filter_factory                                   [% FILTER eval %]
# 
# Create a filter to evaluate template text.
#------------------------------------------------------------------------

sub eval_filter_factory {
    my $context = shift;

    return sub {
	my $text = shift;
	$context->process(\$text);
    }
}


#------------------------------------------------------------------------
# perl_filter_factory                                   [% FILTER perl %]
# 
# Create a filter to process Perl text iff the context EVAL_PERL flag 
# is set.
#------------------------------------------------------------------------

sub perl_filter_factory {
    my $context = shift;
    my $stash = $context->stash;

    return (undef, Template::Exception->new('perl', 'EVAL_PERL is not set'))
	unless $context->eval_perl();

    return sub {
	my $text = shift;
	$Template::Perl::context = $context;
	$Template::Perl::stash = $stash;
	my $out = eval "package Template::Perl; $text";
	$context->throw($@) if $@;
	return $out;
    }
}


#------------------------------------------------------------------------
# redirect_filter_factory($context, $file)    [% Filter redirect(file) %]
#
# Create a filter to redirect the block text to a file.
#------------------------------------------------------------------------

sub redirect_filter_factory {
    my ($context, $file) = @_;
    my $outpath = $context->config->{ OUTPUT_PATH };

    return (undef, Template::Exception->new('file', 'OUTPUT_PATH is not set'))
	unless $outpath;

    sub {
	my $text = shift;
	my $outpath = $context->config->{ OUTPUT_PATH }
	    || return '';
	$outpath .= "/$file";
	local *FP;
	open(FP, ">$outpath") 
	    || die Template::Exception->new('file', "$file: $!");
	print FP $text;
	close(FP);
	return '';
    }
}




1;

