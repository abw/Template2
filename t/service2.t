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
use Template::Service;

#$Template::Service::DEBUG = 1;

my $service = Template::Service->new({
    INCLUDE_PATH => 'test/src:test/lib',
    PRE_PROCESS  => 'config',
    POST_PROCESS => 'footer',
});

$service->_dump();
$service->context->_dump();

print  $service->process('tryme', { r => 'romeo' })
    || $service->error();

