#============================================================= -*-perl-*-
#
# t/meta.t
#
# Test the meta() method in Template::Document.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 2022 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;

$^W = 1;

my $tt = Template->new || die Template->error;
my $template = $tt->template(\*DATA);
my $meta = $template->meta;

is( $meta->{ author }, 'Andy Wardley', 'fetched META author' );
is( $meta->{ animal }, 'Badger', 'fetched META animal' );
is( scalar(keys %$meta), 2, 'two items in meta' );


__END__
[% META
    author = 'Andy Wardley'
    animal = 'Badger'
%]
Hello world!