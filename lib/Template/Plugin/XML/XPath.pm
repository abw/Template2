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
    die Template::Exception->new('XML.XPath', $error);
}


1;

__END__

=head1 NAME

Template::Plugin::XML::XPath - Template Toolkit plugin to the XML::XPath module

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

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::XPath modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::XPath module.
=head1 AUTHOR

This plugin module was written by Andy Wardley E<lt>abw@kfs.orgE<gt>.

The XML::XPath module is by Matt Sergeant E<lt>matt@sergeant.org<gt>.

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For further information see L<XML::XPath>, L<XML::Parser> and 
L<Template::Plugin>.

=cut





