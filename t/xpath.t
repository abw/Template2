#============================================================= -*-perl-*-
#
# t/xpath.t
#
# Test the XML::XPath plugin.
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
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

# I hate having to do this
my $shut_up_warnings = $XML::XPath::VERSION;

eval "use XML::XPath";

if ($@ || $XML::XPath::VERSION < 1.0) {
    skip_all('XML::XPath v1.0 or later not installed');
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/testfile.xml';   

test_expect(\*DATA, undef, { 'xmlfile' => $file });

__END__
-- test --
[% TRY;
     USE xpath = XML.XPath('no_such_file');
     xpath.find('/foo/bar');
   CATCH;
     "ok";
   END
%]
-- expect --
ok

-- test --
[% USE xpath = XML.XPath(xmlfile) -%]
[% FOREACH page = xpath.findnodes('/website/section/page') -%]
page: [% page.getAttribute('title') %]
[% END %]
-- expect --
page: The Foo Page
page: The Bar Page
page: The Baz Page


-- test --
[% USE xpath = XML.XPath(file => xmlfile) -%]
[% FOREACH page = xpath.findnodes('/website/section/page') -%]
page: [% page.getAttribute('title') %]
[% END %]
-- expect --
page: The Foo Page
page: The Bar Page
page: The Baz Page


-- test --
[% USE xpath = XML.XPath(filename => xmlfile) -%]
[% FOREACH page = xpath.findnodes('/website/section/page') -%]
page: [% page.getAttribute('title') %]
[% END %]
-- expect --
page: The Foo Page
page: The Bar Page
page: The Baz Page


-- test --
[% xmltext = BLOCK %]
<html>
<body>
<section id="foo">
  This is the foo section, here is some <b>bold</b> text.
</section>
<section id="foo">
  This is the bar section, here is some <i>italic</i> text
</section>
</body>
</html>
[% END -%]
[% USE xpath = XML.XPath(xmltext) -%]
...
[% FOREACH section = xpath.findnodes('/html/body/section') -%]
[% section.string_value %]
[% END %]

-- expect --
...

  This is the foo section, here is some bold text.


  This is the bar section, here is some italic text

-- test --
[% xmltext = BLOCK -%]
<foo>
<bar baz="10">
  <list>
  <item>one</item>
  <item>two</item>
  </list>
</bar>
</foo>
[% END -%]
[% VIEW xview notfound='xmlstring' -%]
[% BLOCK foo -%]
FOO {
[%- item.content(view) -%]
}
[% END -%]
[% BLOCK bar -%]
  BAR(baz="[% item.getAttribute('baz') %]") {
[%- item.content(view) -%]
}
[% END -%]
[% BLOCK list -%]
  LIST:
[%- item.content(view) -%]
[% END -%]
[% BLOCK item -%]
    * [% item.content(view) -%]
[% END -%]
[% BLOCK xmlstring; item.toString; END %]
[% BLOCK text; item; END %]
[% END -%]

[%- USE xpath = XML.XPath(xmltext);
    foo = xpath.findnodes('/foo');
    xview.print(foo);
-%]
-- expect --
FOO {
  BAR(baz="10") {
    LIST:
      * one
      * two
  
}

}

-- test --
[% xmltext = BLOCK -%]
<foo>
<bar baz="10" fud="11">
  <list>
  <item>one</item>
  <item>two</item>
  </list>
</bar>
</foo>
[% END -%]
[% VIEW xview notfound='xmlstring' -%]
[% BLOCK item -%]
* [% item.content(view) -%]
[% END -%]
[% BLOCK xmlstring; item.starttag; item.content(view); item.endtag; END %]
[% BLOCK text; item; END %]
[% END -%]

[%- USE xpath = XML.XPath(xmltext);
    foo = xpath.findnodes('/foo');
    xview.print(foo);
-%]

-- expect --
<foo>
<bar baz="10" fud="11">
  <list>
  * one
  * two
  </list>
</bar>
</foo>

-- test --
[% xmltext = BLOCK -%]
<greeting type="hello" what="world" />
[% END -%]
[% USE xp = XML.XPath(xml => xmltext);
   xp.find("/greeting[@type='hello']/@what") %]
-- expect --
world


-- test --
[% xmltext = BLOCK -%]
<hello>world</hello>
[% END -%]
[% USE xp = XML.XPath(text => xmltext);
   xp.find("/hello"); %]
-- expect --
world


