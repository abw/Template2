#============================================================= -*-perl-*-
#
# t/cgi.t
#
# Test the CGI plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
use Template::Parser;
$^W = 1;

$Template::Parser::DEBUG = 1;

eval "use CGI";
if ($@) {
    print "1..0\n";
    exit(0);
}


test_expect(\*DATA);

__END__
-- test --
[% USE cgi = CGI('id=abw&name=Andy+Wardley') -%]
name: [% cgi.param('name') %]
name: [% cgi.param('name') %]

[% FOREACH x = cgi.checkbox_group(
		name     => 'words'
                values   => [ 'eenie', 'meenie', 'minie', 'moe' ]
	        defaults => [ 'eenie', 'meenie' ] )   -%]
[% x %]
[% END %]
name: [% cgi.param('name') %]

-- expect --
<INPUT TYPE="checkbox" NAME="words" VALUE="eenie" CHECKED>eenie
<INPUT TYPE="checkbox" NAME="words" VALUE="meenie" CHECKED>meenie
<INPUT TYPE="checkbox" NAME="words" VALUE="minie">minie
<INPUT TYPE="checkbox" NAME="words" VALUE="moe">moe

name: Andy Wardley
