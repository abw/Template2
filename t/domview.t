#============================================================= -*-perl-*-
#
# t/domview.t
#
# Test the XML::DOM plugin presenting via a VIEW
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2001 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2001 Canon Research Centre Europe Ltd.
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

#$Template::Test::DEBUG = 1;
#$Template::Test::PRESERVE = 1;

# I hate having to do this
my $shut_up_warnings = $XML::DOM::VERSION;

eval "use XML::DOM";
if ($@ ||  $XML::DOM::VERSION < 1.27) {
    print "1..0\n";
    exit(0);
}

test_expect(\*DATA);

__END__
-- test --
[% xmltext = BLOCK -%]
<report>
  <section title="Introduction">
    <p>
    Blah blah.
    <ul>
      <li>Item 1</li>
      <li>item 2</li>
    </ul>
    </p>
  </section>
  <section title="The Gory Details">
    ...
  </section>
</report>
[% END -%]
[% USE dom = XML.DOM;
   doc = dom.parse(text => xmltext);
   report = doc.getElementsByTagName('report')
-%]
[% VIEW report_view notfound='xmlstring' %]
# handler block for a <report>...</report> element
[% BLOCK report; item.content(view); END %]

# handler block for a <section title="...">...</section> element
[% BLOCK section -%]
<h1>[% item.title %]</h1>
[% item.content(view) -%]
[% END -%]

# default template block converts item to string representation
[% BLOCK xmlstring; item.toString; END %]
       
# block to generate simple text
[% BLOCK text; item; END %]
[% END -%]
REPORT: [% report_view.print(report) | trim %]
-- expect --
REPORT: <h1>Introduction</h1>

    <p>
    Blah blah.
    <ul>
      <li>Item 1</li>
      <li>item 2</li>
    </ul>
    </p>
  
  <h1>The Gory Details</h1>

    ...
