#============================================================= -*-perl-*-
#
# t/service.t
#
# Test the Template::Service module.
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
use Template::Test;
use Template::Service;
use Template::Document;

my $tt = Template->new({
    INCLUDE_PATH => [ qw( t/test/lib test/lib t/test/src test/src) ],	
#    PRE_PROCESS  => 'header',
#    POST_PROCESS => 'footer',
    BLOCKS       => { demo => \&demo },
    ERROR        => {
	'barf'    => 'barfed',
	'default' => 'error',
    },
});

test_expect(\*DATA, $tt);

__END__
-- test --
foo
-- expect --
foo

