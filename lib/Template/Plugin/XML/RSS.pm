#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::RSS
#
# DESCRIPTION
#
#   Template Toolkit plugin which interfaces to Jonathan Eisenzopf's XML::RSS
#   module.  RSS is the Rich Site Summary format.
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

package Template::Plugin::XML::RSS;

require 5.004;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use XML::RSS;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub load {
    return $_[0];
}

sub new {
    my ($class, $context, $filename) = @_;

    return $class->fail('No filename specified')
	unless $filename;
    
    my $rss = XML::RSS->new
	or return $class->fail('failed to create XML::RSS');

    eval { $rss->parsefile($filename) } and not $@
	or return $class->fail("failed to parse $filename: $@");

    return $rss;
}

1;


__END__

=head1 NAME

Template::Plugin::XML::RSS - Template Toolkit plugin to the XML::RSS module

=head1 SYNOPSIS

    [% USE news = XML.RSS($filename) %]
   
    [% FOREACH item = news.items %]
       [% item.title %]
       [% item.link  %]
    [% END %]

=head1 PRE-REQUISITES

This plugin requires that the XML::Parser and XML::RSS modules be 
installed.  These are available from CPAN:

    http://www.cpan.org/modules/by-module/XML

=head1 DESCRIPTION

This Template Toolkit plugin provides a simple interface to the
XML::RSS module.

    [% USE news = XML.RSS('mysite.rdf') %]

It creates an XML::RSS object, which is then used to parse the RSS
file specified as a parameter in the USE directive.  A reference to
the XML::RSS object is then returned.

An RSS (Rich Site Summary) file is typically used to store short news
'headlines' describing different links within a site.  This example is
extracted from http://slashdot.org/slashdot.rdf.

    <?xml version="1.0"?><rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns="http://my.netscape.com/rdf/simple/0.9/">
    
      <channel>
    	<title>Slashdot:News for Nerds. Stuff that Matters.</title>
    	<link>http://slashdot.org</link>
    	<description>News for Nerds.  Stuff that Matters</description>
      </channel>
    
      <image>
    	<title>Slashdot</title>
    	<url>http://slashdot.org/images/slashdotlg.gif</url>
    	<link>http://slashdot.org</link>
      </image>
      
      <item>
    	<title>DVD CCA Battle Continues Next Week</title>
    	<link>http://slashdot.org/article.pl?sid=00/01/12/2051208</link>
      </item>
      
      <item>
    	<title>Matrox to fund DRI Development</title>
    	<link>http://slashdot.org/article.pl?sid=00/01/13/0718219</link>
      </item>
      
      <item>
    	<title>Mike Shaver Leaving Netscape</title>
    	<link>http://slashdot.org/article.pl?sid=00/01/13/0711258</link>
      </item>
      
    </rdf:RDF>

The attributes of the channel and image elements can be retrieved directly
from the plugin object using the familiar dotted compound notation:

    [% news.channel.title  %]
    [% news.channel.link   %]
    [% news.channel.etc... %]  

    [% news.image.title    %]
    [% news.image.url      %]
    [% news.image.link     %]
    [% news.image.etc...   %]  

The list of news items can be retrieved using the 'items' method:

    [% FOREACH item = news.items %]
       [% item.title %]
       [% item.link  %]
    [% END %]

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 CREDITS

The XML::RSS module, which implements all of the functionality that
this plugin delegates to, was written by Jonathan Eisenzopf 
E<lt>eisen@pobox.comE<gt>.

This plugin was inspired by an article in Web Techniques by Randal 
Schwartz <merlyn@stonehenge.com>.

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS|XML::RSS>,  L<Template::Plugin|Template::Plugin>, 

=cut


