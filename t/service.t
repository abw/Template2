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

#$Template::Service::DEBUG = 1;
#$Template::Parser::DEBUG = 1;

$^W = 1;

sub demo {
    my $context = shift;
    my $stash   = $context->stash;
    my $rval    = $stash->get('r') || $context->throw("No value for 'r'");
#    die "total spasm\n";
    return "r is set to $rval\n";
}

#my $demo = Template::Document->new(\&demo);

my $tt = Template->new({
    INCLUDE_PATH => [ qw( t/test/lib test/lib t/test/src test/src) ],	
    PRE_PROCESS  => 'config header',
    POST_PROCESS => 'footer',
    BLOCKS       => { demo => \&demo },
    ERROR        => {
	'barf'    => 'barfed',
	'default' => 'error',
    },
});

my $service = $tt->service;
my $data = &callsign;
#$data->{ r } = sub { die Template::Exception->new('zak', "blown up\n") };
$data->{ title } = 'This is the TITLE';

print $service->process('tryme', $data)
    || "SERVICE ERROR: " . $service->error(), "\n";

