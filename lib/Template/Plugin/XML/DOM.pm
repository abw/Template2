#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::DOM
#
# DESCRIPTION
#
#   Simple Template Toolkit plugin interfacing to the XML::DOM.pm module.
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

package Template::Plugin::XML::DOM;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use XML::DOM;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my ($class, $context, $filename) = @_;
    my $doc;

    return $class->fail('No filename specified')
	unless $filename;
    
    my $parser = XML::DOM::Parser->new
	or return $class->fail('failed to create XML::DOM::Parser');

    eval { $doc = $parser->parsefile($filename) } and not $@
	or return $class->fail("failed to parse $filename: $@");

    return $doc;
}

package XML::DOM::Element;

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    $self->getAttribute($method);
}

1;

__END__

=head1 NAME

Template::Plugin::XML::DOM - simple Template Toolkit plugin interfacing to the XML::DOM module

=head1 SYNOPSIS

    [% USE doc = XML.DOM('/path/to/file.xml') %]

    # print all HREF attributes of all CODEBASE elements
    [% FOREACH node = doc.getElementsByTagName('CODEBASE') %]
       * [% s.getAttribute('href') %]     # or just '[% s.href %]'
    [% END %]

    # see XML::DOM docs for other methods provided by this object

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::DOM modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 DESCRIPTION

This is a very simple Template Toolkit Plugin interface to the
XML::DOM module.   The plugin loads the XML::DOM module, instantiates
a parser and parser the file passed by name as a parameter.  An 
XML::DOM::Node object is returned through which the XML document
can be traverse.  See L<XML::DOM> for full details.

This plugin also provides an AUTOLOAD method for XML::DOM::Node which 
calls getAttribute() for any undefined methods.  Thus, you can use the 
short form of 

    [% node.attribute %]

in place of

    [% node.getAttribute('attribute') %]

=head1 AUTHOR

This plugin module was written by Andy Wardley E<lt>cre.canon.co.ukE<gt>.

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

L<XML::DOM|XML::DOM>, L<XML::Parser|XML::Parser>,
L<Template::Plugin|Template::Plugin>,

=cut





