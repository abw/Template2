#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::DOM
#
# DESCRIPTION
#
#   Simple Template Toolkit plugin interfacing to the XML::DOM.pm module.
#
# AUTHORS
#   Andy Wardley   <abw@kfs.org>
#   Simon Matthews <sam@knowledgepool.com>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley, Simon Matthews.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Plugin::XML::DOM;

require 5.004;

use strict;
use Template::Plugin;
use XML::DOM;

use base qw( Template::Plugin );
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \%config)
#
# Constructor method for XML::DOM plugin.  Creates an XML::DOM::Parser
# object and initialise plugin configuration.
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    
    my $parser ||= XML::DOM::Parser->new(%$args)
	or $class->_throw("failed to create XML::DOM::Parser\n");

    # we've had to deprecate the old usage because it broke things big time
    # with DOM trees never getting cleaned up.
    $class->_throw("XML::DOM usage has changed - you must now call parse()\n")
	if @_;
    
    bless { 
	_PARSER     => $parser,
	_DOCS       => [ ],
	_CONTEXT => $context,
	_PREFIX  => $args->{ prefix  } || '',
	_SUFFIX  => $args->{ suffix  } || '',
	_DEFAULT => $args->{ default } || '',
	_VERBOSE => $args->{ verbose } || 0,
	_NOSPACE => $args->{ nospace } || 0,
	_DEEP    => $args->{ deep    } || 0,
    }, $class;
}


#------------------------------------------------------------------------
# parse($content, \%named_params)
#
# Parses an XML stream, provided as the first positional argument (assumed
# to be a filename unless it contains a '<' character) or specified in 
# the named parameter hash as one of 'text', 'xml' (same as text), 'file'
# or 'filename'.
#------------------------------------------------------------------------

sub parse {
    my $self   = shift;
    my $args   = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my $parser = $self->{ _PARSER };
    my ($content, $about, $method, $doc);

    # determine the input source from a positional parameter (may be a 
    # filename or XML text if it contains a '<' character) or by using
    # named parameters which may specify one of 'file', 'filename', 'text'
    # or 'xml'

    if ($content = shift) {
	if ($content =~ /\</) {
	    $about  = 'xml text';
	    $method = 'parse';
	}
	else {
	    $about = "xml file $content";
	    $method = 'parsefile';
	}
    }
    elsif ($content = $args->{ text } || $args->{ xml }) {
	$about = 'xml text';
	$method = 'parse';
    }
    elsif ($content = $args->{ file } || $args->{ filename }) {
	$about = "xml file $content";
	$method = 'parsefile';
    }
    else {
	return $self->_throw('no filename or xml text specified');
    }

    # parse the input source using the appropriate method determined above
    eval { $doc = $parser->$method($content) } and not $@
	or return $self->_throw("failed to parse $about: $@");

    # update XML::DOM::Document to contain config details
    my @args = qw( _CONTEXT _PREFIX _SUFFIX _VERBOSE _NOSPACE _DEEP _DEFAULT );
    @$doc{ @args } = @$self{ @args };

    # keep track of all DOM docs for subsequent dispose()
    push(@{ $self->{ _DOCS } }, $doc);

    return $doc;
}


#------------------------------------------------------------------------
# _throw($errmsg)
#
# Raised a Template::Exception of type XML.DOM via die().
#------------------------------------------------------------------------

sub _throw {
    my ($self, $error) = @_;
    die Template::Exception->new('XML.DOM', $error);
}


#------------------------------------------------------------------------
# DESTROY
#
# Cleanup method which calls dispose() on any and all DOM documents 
# created by this object.  Also breaks any circular references that
# may exist with the context object.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    # call dispose() on each document produced by this parser
    foreach my $doc (@{ $self->{ _DOCS } }) {
	delete $doc->{ _CONTEXT };
	$doc->dispose();
    }
    delete $self->{ _CONTEXT };
}



#========================================================================
package XML::DOM::Node;
#========================================================================

#------------------------------------------------------------------------
# toTemplate($prefix, $suffix, \%named_params)
#
# Process the current node as a template.
#------------------------------------------------------------------------

sub toTemplate {
    my $self = shift;
    _template_node($self, $self->_args(@_));
}


#------------------------------------------------------------------------
# childrenToTemplate($prefix, $suffix, \%named_params)
#
# Process all the current node's children as templates.
#------------------------------------------------------------------------

sub childrenToTemplate {
    my $self = shift;
    _template_kids($self, $self->_args(@_));
}


#------------------------------------------------------------------------
# allChildrenToTemplate($prefix, $suffix, \%named_params)
#
# Process all the current node's children, and their children, and 
# their children, etc., etc., as templates.  Same effect as calling the
# childrenToTemplate() method with the 'deep' option set.
#------------------------------------------------------------------------

sub allChildrenToTemplate {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{ deep } = 1;
    _template_kids($self, $args);
}


#------------------------------------------------------------------------
# _args($prefix, $suffix, \%name_params)
#
# Reads the optional positional parameters, $prefix and $suffix, and 
# also examines any named parameters hash to construct a set of 
# current configuration parameters.  Where not specified directly, the 
# object defaults are used.
#------------------------------------------------------------------------

sub _args {
    my $self = shift;
    my $doc  = $self->{ Doc };
    my $args = ref $_[-1] eq 'HASH' ? pop(@_) : { };

    return {
	prefix  => @_ ? shift : $args->{ prefix  } || $doc->{ _PREFIX  },
	suffix  => @_ ? shift : $args->{ suffix  } || $doc->{ _SUFFIX  },
	verbose =>              $args->{ verbose } || $doc->{ _VERBOSE },
	nospace =>              $args->{ nospace } || $doc->{ _NOSPACE },
	deep    =>              $args->{ deep    } || $doc->{ _DEEP    },
	default =>              $args->{ default } || $doc->{ _DEFAULT },
    };
}


#------------------------------------------------------------------------
# _template_node($node, $args, $vars)
#
# Process a template for the current DOM node where the template name 
# is taken from the node TagName, with any specified 'prefix' and/or 
# 'suffix' applied.  The 'default' argument can also be provided to 
# specify a default template to be used when a specific template can't
# be found.  The $args parameter referenced a hash array through which
# these configuration items are passed (see _args()).  The current DOM 
# node is made available to the template as the variable 'node', along 
# with any other variables passed in the optional $vars hash reference.
# To permit the 'children' and 'prune' callbacks to be raised as node
# methods (see _template_kids() below), these items, if defined in the
# $vars hash, are copied into the node object where its AUTOLOAD method
# can find them.
#------------------------------------------------------------------------

sub _template_node {
    my $node = shift || die "no XML::DOM::Node reference\n";
    my $args = shift || { };
    my $vars = shift || { };
    my $context = $node->{ Doc }->{ _CONTEXT };
    my $output = '';

    # if this is not a tag then it is text so output it
    unless ($node->{ TagName }) {
	if ($args->{ verbose }) {
	    $output = $node->toString();
	    $output =~ s/\s+$// if $args->{ nospace };
	}
    }
    else {
	my $element = ( $args->{ prefix  } || '' )
	            .   $node->{ TagName }
                    . ( $args->{ suffix  } || '' );

	# locate a template by name built from prefix, tagname and suffix
	# or fall back on any default template specified
	my $template = $context->template($element);
	$template = $context->template($args->{ default }) 
	    if ! $template && $args->{ default };
	$template = $element unless $template;

	# copy 'children' and 'prune' callbacks into node object (see AUTOLOAD)
	$node->{ _TT_CHILDREN } = $vars->{ children };
	$node->{ _TT_PRUNE } = $vars->{ prune };

	# add node reference to existing vars hash
	$vars->{ node } = $node;
	
	$output = $context->include($template, $vars); 
	
	# break any circular references
	delete $vars->{ node };
	delete $node->{ _TT_CHILDREN };
	delete $node->{ _TT_PRUNE };
    }

    return $output;
}


#------------------------------------------------------------------------
# _template_kids($node, $args)
#
# Process all the children of the current node as templates, via calls 
# to _template_node().  If the 'deep' argument is set, then the process
# will continue recursively.  In this case, the node template is first 
# processed, followed by any children of that node (i.e. depth first, 
# parent before).  A closure called 'children' is created and added
# to the Stash variables passed to _template_node().  This can be called 
# from the parent template to process all child nodes at the current point.
# This then "prunes" the tree preventing the children from being processed
# after the parent template.  A 'prune' callback is also added to prune 
# the tree without processing the children.  Note that _template_node()
# copies these callbacks into each parent node, allowing them to be called
# as [% node.
#------------------------------------------------------------------------

sub _template_kids {
    my $node = shift || die "no XML::DOM::Node reference\n";
    my $args = shift || { };
    my $context = $node->{ Doc }->{ _CONTEXT };
    my $output = '';

    foreach my $kid ( $node->getChildNodes() ) {
	# define some callbacks to allow template to call [% content %]
	# or [% prune %].  They are also inserted into each node reference
	# so they can be called as [% node.content %] and [% node.prune %]
	my $prune = 0;
	my $vars  = { };
	$vars->{ children } = sub {
	    $prune = 1;
	    _template_kids($kid, $args);
	};
	$vars->{ prune } = sub {
	    $prune = 1;
	    return '';
	};
		
	$output .= _template_node($kid, $args, $vars);
	$output .= _template_kids($kid, $args)
	    if $args->{ deep } && ! $prune;
    }
    return $output;
}


#========================================================================
package XML::DOM::Element;
#========================================================================

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    my $attrib;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    # call 'content' or 'prune' callbacks, if defined (see _template_node())
    return &$attrib()
	if ($method =~ /^children|prune$/)
	    && defined($attrib = $self->{ "_TT_\U$method" })
		&& ref $attrib eq 'CODE';

    return $attrib
	if defined ($attrib = $self->getAttribute($method));

    return '';
}


1;

__END__

=head1 NAME

Template::Plugin::XML::DOM - Template Toolkit plugin to the XML::DOM module

=head1 SYNOPSIS

    # load plugin
    [% USE dom = XML.DOM %]

    # also provide XML::Parser options
    [% USE dom = XML.DOM(ProtocolEncoding => 'ISO-8859-1') %]

    # parse an XML file
    [% doc = dom.parse(filename) %]
    [% doc = dom.parse(file => filename) %]

    # parse XML text
    [% doc = dom.parse(xmltext) %]
    [% doc = dom.parse(text => xmltext) %]

    # call any XML::DOM methods on document/element nodes
    [% FOREACH node = doc.getElementsByTagName('CODEBASE') %]
       * [% node.getAttribute('href') %]     # or just '[% node.href %]'
    [% END %]

    # process template for DOM node (template name is node TagName)
    [% node.toTemplate %]

    # process templates for all children of DOM node
    [% node.childrenToTemplate %]

    # process templates recursively for all descendants of DOM node
    [% node.allChildrenToTemplate %]

    # examples of processing options
    [% node.toTemplate(verbose=>1) %]
    [% node.childrenToTemplate(prefix=>'mytemplates/' suffix=>'.tt2') %]
    [% node.allChildrenToTemplate(default=>'mytemplates/anynode.tt2') %]

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::DOM modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::DOM module.
The plugin loads the XML::DOM module and creates an XML::DOM::Parser
object which is stored internally.  The parse() method can then be
called on the plugin to parse an XML stream into a DOM document.

    [% USE dom = XML.DOM %]
    [% doc = dom.parse('/tmp/myxmlfile') %]

NOTE: previous versions of this XML::DOM plugin expected a filename to
be passed as an argument to the constructor.  This is no longer supported
due to the fact that it caused a serious memory leak.  We apologise for 
the inconvenience but must insist that you change your templates as 
shown:

    # OLD STYLE: now fails with a warning
    [% USE dom = XML.DOM('tmp/myxmlfile') %]

    # NEW STYLE: do this instead
    [% USE dom = XML.DOM %]
    [% doc = dom.parse('tmp/myxmlfile') %]

The root of the problem lies in XML::DOM creating massive circular
references in the object models it constructs.  The dispose() method
must be called on each document to release the memory that it would
otherwise hold indefinately.  The XML::DOM plugin object (i.e. 'dom'
in these examples) acts as a sentinel for the documents it creates
('doc' and any others).  When the plugin object goes out of scope at
the end of the current template, it will automatically call dispose()
on any documents that it has created.  Note that if you dispose of the
the plugin object before the end of the block (i.e.  by assigning a
new value to the 'dom' variable) then the documents will also be
disposed at that point and should not be used thereafter.

    [% USE dom = XML.DOM %]
    [% doc = dom.parse('/tmp/myfile') %]
    [% dom = 'new value' %]     # releases XML.DOM plugin and calls
                                # dispose() on 'doc', so don't use it!

Any template processing parameters (see toTemplate() method and
friends, below) can be specified with the constructor and will be used
to define defaults for the object.

    [% USE dom = XML.DOM(prefix => 'theme1/') %]

The plugin constructor will also accept configuration options destined
for the XML::Parser object:

    [% USE dom = XML.DOM(ProtocolEncoding => 'ISO-8859-1') %]

=head1 METHODS

=head2 parse()

The parse() method accepts a positional parameter which contains a filename
or XML string.  It is assumed to be a filename unless it contains a E<lt>
character.

    [% xmlfile = '/tmp/foo.xml' %]
    [% doc = dom.parse(xmlfile) %]

    [% xmltext = BLOCK %]
    <xml>
      <blah><etc/></blah>
      ...
    </xml>
    [% END %]
    [% doc = dom.parse(xmltext) %]

The named parameters 'file' (or 'filename') and 'text' (or 'xml') can also
be used:

    [% doc = dom.parse(file = xmlfile) %]
    [% doc = dom.parse(text = xmltext) %]

The parse() method returns an instance of the XML::DOM::Document object 
representing the parsed document in DOM form.  You can then call any 
XML::DOM methods on the document node and other nodes that its methods
may return.  See L<XML::DOM> for full details.

    [% FOREACH node = doc.getElementsByTagName('CODEBASE') %]
       * [% node.getAttribute('href') %]
    [% END %]

This plugin also provides an AUTOLOAD method for XML::DOM::Node which 
calls getAttribute() for any undefined methods.  Thus, you can use the 
short form of 

    [% node.attrib %]

in place of

    [% node.getAttribute('attrib') %]

=head2 toTemplate()

This method will process a template for the current node on which it is 
called.  The template name is constructed from the node TagName with any
optional 'prefix' and/or 'suffix' options applied.  A 'default' template 
can be named to be used when the specific template cannot be found.  The 
node object is available to the template as the 'node' variable.

Thus, for this XML fragment:

    <page title="Hello World!">
       ...
    </page>

and this template definition:

    [% BLOCK page %]
    Page: [% node.title %]
    [% END %]

the output of calling toTemplate() on the E<lt>pageE<gt> node would be:

    Page: Hello World!

=head2 childrenToTemplate()

Effectively calls toTemplate() for the current node and then for each of 
the node's children.  By default, the parent template is processed first,
followed by each of the children.  The 'children' closure can be called
from within the parent template to have them processed and output 
at that point.  This then suppresses the children from being processed
after the parent template.

Thus, for this XML fragment:

    <foo>
      <bar id="1"/>
      <bar id="2"/>
    </foo>

and these template definitions:

    [% BLOCK foo %]
    start of foo
    end of foo 
    [% END %]

    [% BLOCK bar %]
    bar [% node.id %]
    [% END %]

the output of calling childrenToTemplate() on the parent E<lt>fooE<gt> node 
would be:

    start of foo
    end of foo
    bar 1
    bar 2

Adding a call to [% children %] in the 'foo' template:

    [% BLOCK foo %]
    start of foo
    [% children %]
    end of foo 
    [% END %]

then creates output as:

    start of foo
    bar 1 
    bar 2
    end of foo

The 'children' closure can also be called as a method of the node, if you 
prefer:

    [% BLOCK foo %]
    start of foo
    [% node.children %]
    end of foo 
    [% END %]

The 'prune' closure is also defined and can be called as [% prune %] or
[% node.prune %].  It prunes the currrent node, preventing any descendants
from being further processed.

    [% BLOCK anynode %]
    [% node.toString; node.prune %]
    [% END %]

=head2 allChildrenToTemplate()

Similar to childrenToTemplate() but processing all descendants (i.e. children
of children and so on) recursively.  This is identical to calling the 
childrenToTemplate() method with the 'deep' flag set to any true value.

=head1 BUGS

The childrenToTemplate() and allChildrenToTemplate() methods can easily
slip into deep recursion.

The 'verbose' and 'nospace' options are not documented.  They may 
change in the near future.

=head1 AUTHOR

This plugin module was written by Andy Wardley E<lt>abw@kfs.orgE<gt>
and Simon Matthews E<lt>sam@knowledgepool.comE<gt>.

The XML::DOM module is by Enno Derksen E<lt>enno@att.comE<gt> and Clark 
Cooper E<lt>coopercl@sch.ge.comE<gt>.  It extends the the XML::Parser 
module, also by Clark Cooper which itself is built on James Clark's expat
library.

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For further information see L<XML::DOM>, L<XML::Parser> and 
L<Template::Plugin>.

=cut





