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

eval "use XML::DOM";
if ($@) {
    print "1..0\n";
    exit(0);
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/testfile.xml';   

test_expect(\*DATA, undef, { 'xmlfile' => $file });

__END__
-- test --
[% USE doc = XML.DOM(xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page




