#============================================================= -*-perl-*-
#
# t/dom.t
#
# Test the XML::DOM plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

# I hate having to do this
my $shut_up_warnings = $XML::DOM::VERSION;

eval "use XML::DOM";

# XML::DOM version 1.25 (and earlier?) dump core with Perl 5.006
if ($@ || ($] == 5.006 && $XML::DOM::VERSION <= 1.25)) {
    print "1..0\n";
    exit(0);
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/testfile.xml';   

test_expect(\*DATA, undef, { 'xmlfile' => $file });

__END__
-- test --
[% TRY;
     # old usage style is now deprecated (it was badly broken)
     USE dom = XML.DOM(xmlfile);
   CATCH XML;
     error;
   END
%]
-- expect --
XML.DOM error - XML::DOM usage has changed - you must now call parse()

-- test --
[% TRY;
     # specify a dummy encoding, just to make sure it gets passed as an option
     USE dom = XML.DOM(ProtocolEncoding = 'ISO-666');
     doc = dom.parse(xmlfile);
   CATCH XML.DOM;
     error.info.split(' /').0;
   END;
%]

-- expect --
failed to parse xml file

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(file => xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(filename => xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% global.xmltext = BLOCK %]
<website id="webzone1">
  <section name="alpha" title="The Alpha Zone">
    <page href="/foo/bar" title="The Foo Page"><msg>Hello World!</msg></page>
    <page href="/bar/baz" title="The Bar Page"/>
    <page href="/baz/qux" title="The Baz Page"/>
  </section>
</website>
[% END -%]
[% USE dom = XML.DOM -%]
[% doc = dom.parse(global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(text => global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(xml => global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE parser = XML.DOM -%]
[% doc = parser.parse(global.xmltext) -%]
[% FOREACH node = doc.getElementsByTagName('section') -%]
[% node.toTemplate %]
[% END %]

[% BLOCK section -%]
Section name: [% node.name %]  title: [% node.title %]
[% node.childrenToTemplate -%]
[% END %]

[% BLOCK page -%]
<a href="[% node.href %]">[% node.title %]</a>
[% node.childrenToTemplate -%]
[% END %]

[% BLOCK msg -%]
<b>[% node.childrenToTemplate(verbose=1) %]</b>
[% END %]


-- expect --
Section name: alpha  title: The Alpha Zone
<a href="/foo/bar">The Foo Page</a>
<b>Hello World!</b>
<a href="/bar/baz">The Bar Page</a>
<a href="/baz/qux">The Baz Page</a>

-- test --
[% xmltext = BLOCK %]
<xml>
<section id="a" title="First Section">>
  <page id="a1" title="page 1">

    <head><author>Andy Wardley</author></head>
    <body>
    This is the first page
    </body>
  </page>
  <page id="a2" title="page 2">
    This is the second page
  </page>
</section>
<section id="b" title="Second Section">
  <page id="b1" title="page 1">
    This is the first page in section b
  </page>
  <page id="b2" title="page 2">
    This is the second page in section b
  </page>
</section>
</xml>
[% END -%]
[% USE parser = XML.DOM -%]
[% doc = parser.parse(xmltext) -%]
[% node.allChildrenToTemplate(default='anynode') 
     FOREACH node = doc.getChildNodes %]

[% BLOCK section -%]
SECTION [% node.id %]: [% node.title %]
[% children -%]
END OF SECTION [% node.id %]
[% END %]

[% BLOCK page -%]
PAGE: [% node.title %]
[% node.children -%]
END OF PAGE
[% END %]

[% BLOCK head -%]
HEADER: [% node.toString; prune %]END_HEADER
[% END %]

[% BLOCK anynode -%]
<any>[% node.toString; node.prune %]</any>
[% END %]
-- expect --
SECTION a: First Section
PAGE: page 1
HEADER: <head><author>Andy Wardley</author></head>END_HEADER
<any><body>
    This is the first page
    </body></any>
END OF PAGE
PAGE: page 2
END OF PAGE
END OF SECTION a
SECTION b: Second Section
PAGE: page 1
END OF PAGE
PAGE: page 2
END OF PAGE
END OF SECTION b
