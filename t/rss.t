#============================================================= -*-perl-*-
#
# t/rss.t
#
# Test the XML::RSS plugin.
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

eval "use XML::RSS";
if ($@) {
    print "1..0\n";
    exit(0);
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/example.rdf';   

test_expect(\*DATA, undef, { 'newsfile' => $file });

__END__
-- test --
[% USE news = XML.RSS(newsfile) -%]
[% FOREACH item = news.items -%]
* [% item.title %]
  [% item.link  %]

[% END %]

-- expect --
* I Read the News Today
  http://oh.boy.com/

* I am the Walrus
  http://goo.goo.ga.joob.org/

-- test --
[% USE news = XML.RSS(newsfile) -%]
[% news.channel.title %]
[% news.channel.link %]

-- expect --
Template Toolkit XML::RSS Plugin
http://template-toolkit.org/plugins/XML/RSS

-- test --
[% USE news = XML.RSS(newsfile) -%]
[% news.image.title %]
[% news.image.url %]

-- expect --
Test Image
http://www.myorg.org/images/test.png





