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
use lib qw( lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

# I hate having to do this
my $shut_up_warnings = $XML::XPath::VERSION;

eval "use XML::XPath";

if ($@ || $XML::XPath::VERSION < 1.0) {
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
     USE xpath = XML.XPath('no_such_file');
     xpath.findvalue('/foo/bar');
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
