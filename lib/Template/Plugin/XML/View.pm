#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::View
#
# DESCRIPTION
#   Template Toolkit plugin to parse XML and generate a view by raising
#   events to a Template::View object for each element in the XML source.
#
#   -- UNDER CONSTRUCTION -- NOT INCLUDED IN THE MAIN DISTRIBUTION --
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

package Template::Plugin::XML::View;

require 5.004;

use strict;
use Template::Plugin;
use XML::Parser;

use base qw( Template::Plugin );
use vars qw( $VERSION $DEBUG $XML_PARSER_ARGS $ELEMENT );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG = 1 unless defined $DEBUG;
$XML_PARSER_ARGS = {
    ErrorContext  => 4,
    Namespaces    => 1,
    ParseParamEnt => 1,
};

$ELEMENT = 'Template::Plugin::XML::View::Element';

#------------------------------------------------------------------------
# new($context, $file_or_text, \%config)
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my ($parser, $input, $about, $method);

    # determine the input source from a positional parameter (may be a 
    # filename or XML text if it contains a '<' character) or by using
    # named parameters which may specify one of 'file', 'filename', 'text'
    # or 'xml'

    if ($input = shift) {
	if ($input =~ /\</) {
	    $about  = 'xml text';
	    $method = 'parse';
	}
	else {
	    $about = "xml file $input";
	    $method = 'parsefile';
	}
    }
    elsif ($input = $args->{ text } || $args->{ xml }) {
	$about = 'xml text';
	$method = 'parse';
    }
    elsif ($input = $args->{ file } || $args->{ filename }) {
	$about = "xml file $input";
	$method = 'parsefile';
    }
#    else {
#	return $self->_throw('no filename or xml text specified');
#    }

    my $xpargs = {
	%$XML_PARSER_ARGS,
	map { defined $args->{$_} ? ( $_, $args->{$_} ) : ( ) }
	qw( ErrorContext Namespaces ParseParamEnt ),
    };
    $parser = XML::Parser->new(
	%$xpargs,
	Style    => 'Template::Plugin::XML::View::Parser',
        Handlers => {
	    Init => sub {
		my $expat = shift;
		my $handler = $ELEMENT->new( document => { } );
		DEBUG("[Init]\n");
		$expat->{ _TT2_XVIEW_TEXT    }  = '';
		$expat->{ _TT2_XVIEW_RESULT  }  = '';
		$expat->{ _TT2_XVIEW_CONTEXT }  = $context;
		$expat->{ _TT2_XVIEW_STACK   }  = [ $handler ];
	    },
	},
    );
    my $result = $parser->$method($input);

    print STDERR "result: $result\n";
    return $result;
}


#------------------------------------------------------------------------
# _throw($errmsg)
#
# Raise a Template::Exception of type XML.View via die().
#------------------------------------------------------------------------

sub _throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('XML.View', $error));
}

sub DEBUG { print STDERR @_ };


#========================================================================
# Template::Plugin::XML::View::Parser
#
# Package defines subroutines which are called by the XML::Parser
# instance.  They manipulate a stack of T-::P-::XML::View::Element
# objects which each represent nested elements currently under parse
# at any time, with the innermost element object on top of the stack.
# These subs call the element() 
#========================================================================

package Template::Plugin::XML::View::Parser;
use vars qw( $DEBUG $ELEMENT );

*DEBUG   = \*Template::Plugin::XML::View::DEBUG;
$ELEMENT = 'Template::Plugin::XML::View::Element';


sub OldInit { 
    my $expat = shift;
    my $handler = $ELEMENT->new( document => { } );
    DEBUG("[Init]\n");
    $expat->{ _TT2_XVIEW_TEXT   }  = '';
    $expat->{ _TT2_XVIEW_RESULT }  = '';
    $expat->{ _TT2_XVIEW_STACK  }  = [ $handler ];
}

sub Start {
    my ($expat, $name, %attr) = @_;
    my $attr = \%attr;

    # flush any character content
    Text($expat) if length $expat->{ _TT2_XVIEW_TEXT };

    if ($DEBUG) {
	my $iattr = join(' ', map { "$_=\"$attr{$_}\"" } keys %attr);
	$attr = " $attr" if $attr;
	DEBUG("[Start] <$name$attr>\n");
    }

    my $stack = $expat->{ _TT2_XVIEW_STACK };

    my $element = $ELEMENT->new($name, \%attr)
	|| $stack->[-1]->throw($ELEMENT->error());

    push(@$stack, $element);

#    my $new = $top->element($expat, $name, \%attr)
#	|| $top->throw($top->error());	    # just throw parse errors for now

}

sub End {
    my ($expat, $name) = @_;

    # flush any character content
    Text($expat) if length $expat->{ _TT2_XVIEW_TEXT };

    DEBUG("[End] </$name>\n") if $DEBUG;

    my $stack = $expat->{ _TT2_XVIEW_STACK };
    my $top = pop(@$stack);
    my $end = $top->end($expat, $name)
	|| $top->throw($top->error());
    if (@$stack) {
	$stack->[-1]->child($expat, $name, $end);
    }
    else {
	DEBUG("popped last handler off stack\n") if $DEBUG;
	$expat->{ _TT2_XVIEW_RESULT } = $end;
    }
}

sub Char {
    my ($expat, $char) = @_;

    DEBUG("[Char] [$char]\n") if $DEBUG;

    # push character content onto buffer
    $expat->{ _TT2_XVIEW_TEXT } .= $char;

}

#------------------------------------------------------------------------
# Text()
#
# This is an extension subroutine which we're using to buffer chunks
# of Char input into complete text blocks.  These then get notified to 
# the parent in one happy bundle rather than several scraggly lumps.
#------------------------------------------------------------------------

sub Text {
    my $expat = shift;
    my $text  = $expat->{ _TT2_XVIEW_TEXT };

    if ($DEBUG) {
	my $dbgtext = $text;
	$dbgtext =~ s/\n/\\n/g;
	DEBUG("[Text] [$dbgtext]\n") if $DEBUG;
    }

    $expat->{ _TT2_XVIEW_STACK }->[-1]->text($expat, $text);
    $expat->{ _TT2_XVIEW_TEXT } = '';
}


sub Final {
    my $expat = shift;
    my $stack = $expat->{ _TT2_XVIEW_STACK };
    my $top = pop(@$stack) || die "corrupt stack in Final";
    my $end = $top->end($expat)
	|| $top->throw($top->error());
    my $r = $expat->{ _TT2_VIEW_RESULT } || $end;
    DEBUG("[Final] => [$r]\n") if $DEBUG;
    return $r;
}



#========================================================================
# Template::Plugin::XML::View::Element
#
# Implements a parser handler for representing each element in the 
#========================================================================

package Template::Plugin::XML::View::Element;


sub new {
    my ($class, $name, $attr) = @_;
    bless {
	name    => $name,
	attr    => $attr,
	content => [ ],
    }, $class;
}

# called to receive character content
sub text {
    my $self = shift;
    my $expat = shift;
    push(@{ $self->{ content } }, @_);
}

# called to receive completed child element
sub child {
    my ($self, $expat, $name, $child) = @_;
    push(@{ $self->{ content } }, $child);    
}

sub end {
    my ($self, $expat, $name) = @_;
    my $context = $expat->{ _TT2_XVIEW_CONTEXT };
    my $attr = $self->{ attr };
    $attr->{ content } = join('', @{ $self->{ content } });
    return $attr->{ content } unless $name;
    $context->process($name, $attr);
#    return $self;
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

Template::Plugin::XML::Simple - Plugin interface to XML::Simple

=head1 SYNOPSIS

    # load plugin and specify XML file to parse
    [% USE xml = XML.Simple(xml_file_or_text) %]

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::Simple module.

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::Simple modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 AUTHORS

This plugin wrapper module was written by Andy Wardley
E<lt>abw@kfs.orgE<gt>.

The XML::Simple module which implements all the core functionality 
was written by Grant McLean E<lt>grantm@web.co.nzE<gt>.

=head1 VERSION

2.06, distributed as part of the
Template Toolkit version 2.03, released on 09 April 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<XML::Simple|XML::Simple>, L<XML::Parser|XML::Parser>

