#============================================================= -*-perl-*-
#
# t/xmlsimple.t
#
# Test the XML::Simple plugin.
#
# Written by Kenny Gatdula <kennyg@pobox.com>
#
# Copyright (C) 2004 Kenny Gatdula.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

$Template::Test::DEBUG = 0;
#$Template::Test::DEBUG = 1;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $tt1 = Template->new({
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],
    ABSOLUTE => 1,
});

ok(1);

eval "use XML::Simple";

if ($@ || $XML::Simple::VERSION < 2) {
    skip_all('XML::Simple v2.0 or later not installed');
}


# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/testfile.xml';

test_expect(\*DATA, $tt1, { 'xmlfile' => $file });

__END__
-- test --
[% TRY;
     USE xmlsimple = XML.Simple('no_such_file');
   CATCH;
     error;
   END
%]
-- expect --
file error - no_such_file: not found


-- test --
[% USE xml = XML.Simple(xmlfile) -%]
[% xml.section.name -%]
-- expect --
alpha

-- test --
[% USE xs = XML.Simple -%]
[% xml = xs.XMLin( './test/xml/testfile.xml') -%]
[% xml.section.title -%]
-- expect --
The Alpha Zone

-- test --
[% USE xs = XML.Simple -%]
[% xml = xs.XMLin( './test/xml/testfile.xml') -%]
[% xmlout = xs.XMLout(xml) -%]
[% xmlout -%]
-- expect --
<opt id="webzone1">
  <section name="alpha" title="The Alpha Zone">
    <page href="/foo/bar" title="The Foo Page" />
    <page href="/bar/baz" title="The Bar Page" />
    <page href="/baz/qux" title="The Baz Page" />
  </section>
</opt>
