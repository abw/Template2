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

# I hate having to do this
my $shut_up_warnings = $XML::RSS::VERSION;

eval "use XML::RSS";
skip_all('XML::RSS v 0.9 or later not installed')
    if $@ || ($] == 5.006 && $XML::RSS::VERSION < 0.9);

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/example.rdf';   

local *RSS;
open RSS, $file or die "Can't open $file: $!";
my $data = join "" => <RSS>;
close RSS;

test_expect(\*DATA, undef, { 'newsfile' => $file, 'newsdata' => $data });

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

-- test --
[% USE news = XML.RSS(newsdata) -%]
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
[% USE news = XML.RSS(newsdata) -%]
[% news.channel.title %]
[% news.channel.link %]

-- expect --
Template Toolkit XML::RSS Plugin
http://template-toolkit.org/plugins/XML/RSS

-- test --
[% USE news = XML.RSS(newsdata) -%]
[% news.image.title %]
[% news.image.url %]

-- expect --
Test Image
http://www.myorg.org/images/test.png



