#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::XPath
#
# DESCRIPTION
#
#   Template Toolkit plugin interfacing to the XML::XPath.pm module.
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
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Plugin::XML::XPath;

require 5.004;

use strict;
use Template::Plugin;
use XML::XPath;

use base qw( Template::Plugin );
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \%config)
#
# Constructor method for XML::XPath plugin.  Creates an XML::XPath
# object and initialises plugin configuration.
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my ($content, $about);

    # determine the input source from a positional parameter (may be a 
    # filename or XML text if it contains a '<' character) or by using
    # named parameters which may specify one of 'file', 'filename', 'text'
    # or 'xml'

    if ($content = shift) {
	if ($content =~ /\</) {
	    $about = 'xml text';
	    $args->{ xml } = $content;
	}
	else {
	    $about = "xml file $content";
	    $args->{ filename } = $content;
	}
    }
    elsif ($content = $args->{ text }) {
	$about = 'xml text';
	$args->{ xml } = $content;
    }
    elsif ($content = $args->{ file }) {
	$about = "xml file $content";
	$args->{ filename } = $content;
    }
    else {
	return $class->_throw('no filename or xml text specified');
    }
    
    return XML::XPath->new(%$args)
	or $class->_throw("failed to create XML::XPath::Parser\n");
}



#------------------------------------------------------------------------
# _throw($errmsg)
#
# Raise a Template::Exception of type XML.XPath via die().
#------------------------------------------------------------------------

sub _throw {
    my ($self, $error) = @_;
    print STDERR "about to throw $error\n";
    die Template::Exception->new('XML.XPath', $error);
}


#========================================================================
package XML::XPath::Node::Element;
#========================================================================

#------------------------------------------------------------------------
# present($view)
#
# Method to present an element node via a view.
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;
    $view->view($self->getName(), $self);
}

sub content {
    my ($self, $view) = @_;
    my $output = '';
    foreach my $node (@{ $self->getChildNodes }) {
	$output .= $node->present($view);
    }
    return $output;
}

#========================================================================
package XML::XPath::Node::Text;
#========================================================================

#------------------------------------------------------------------------
# present($view)
#
# Method to present a text node via a view.
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;
    $view->view('text', $self->string_value);
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

Template::Plugin::XML::XPath - Plugin interface to XML::XPath

=head1 SYNOPSIS

    # load plugin and specify XML file to parse
    [% USE xpath = XML.XPath(xmlfile) %]
    [% USE xpath = XML.XPath(file => xmlfile) %]
    [% USE xpath = XML.XPath(filename => xmlfile) %]

    # load plugin and specify XML text to parse
    [% USE xpath = XML.XPath(xmltext) %]
    [% USE xpath = XML.XPath(xml => xmltext) %]
    [% USE xpath = XML.XPath(text => xmltext) %]

    # then call any XPath methods (see XML::XPath docs)
    [% FOREACH page = xpath.findnodes('/html/body/page') %]
       [% page.getAttribute('title') %]
    [% END %]

    # define VIEW to present node(s)
    [% VIEW repview notfound='xmlstring' %]
       # handler block for a <report>...</report> element
       [% BLOCK report %]
          [% item.content(view) %]
       [% END %]

       # handler block for a <section title="...">...</section> element
       [% BLOCK section %]
       <h1>[% item.getAttribute('title') %]</h1>
       [% item.content(view) %]
       [% END %]

       # default template block converts item to string representation
       [% BLOCK xmlstring; item.toString; END %]
       
       # block to generate simple text
       [% BLOCK text; item; END %]
    [% END %]

    # now present node (and children) via view
    [% repview.print(page) %]

    # or print node content via view
    [% page.content(repview) %]

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::XPath modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::XPath module.

All methods implemented by the XML::XPath modules are available.  In
addition, the XML::XPath::Node::Element module implements
present($view) and content($view) methods method for seamless
integration with Template Toolkit VIEWs.  The XML::XPath::Node::Text
module is also adorned with a present($view) method which presents
itself via the view using the 'text' template.

=head1 AUTHORS

This plugin module was written by Andy Wardley E<lt>abw@kfs.orgE<gt>.

The XML::XPath module is by Matt Sergeant E<lt>matt@sergeant.orgE<gt>.

=head1 VERSION

2.22, distributed as part of the
Template Toolkit version 2.04f, released on 10 September 2001.

=head1 COPYRIGHT

  Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<XML::XPath|XML::XPath>, L<XML::Parser|XML::Parser>

