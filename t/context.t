#============================================================= -*-perl-*-
#
# t/context.t
#
# Test the Template::Context.pm module.
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

#ntests(3);

my $tt = Template->new({
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],	
    TRIM         => 1,
    POST_CHOMP   => 1,
});

my $ttperl = Template->new({
    INCLUDE_PATH => [ qw( t/test/lib test/lib ) ],	
    TRIM         => 1,
    EVAL_PERL    => 1,
    POST_CHOMP   => 1,
});

# test we created a context object and check internal values
my $context = $tt->service->context();
ok( $context );
ok( $context->trim() );
ok( ! $context->eval_perl() );

ok( $context = $ttperl->service->context() );
ok( $context->trim() );
ok( $context->eval_perl() );

# test we can fetch a template via template()
my $template = $context->template('header');
ok( $template );
ok( UNIVERSAL::isa($template, 'Template::Document') );

# test that non-existance of a template is reported
$template = $context->template('no_such_template');
ok( ! $template );
ok( $context->error() eq 'no_such_template: template not found' );

# check that template() returns CODE and Template::Document refs intact
my $code = sub { return "this is a hard-coded template" };
$template = $context->template($code);
ok( $template eq $code );

my $doc = "this is a document";
$doc = bless \$doc, 'Template::Document';
$template = $context->template($doc);
ok( $template eq $doc );
ok( $$doc = 'this is a document' );

# check the use of visit() and leave() to add temporary BLOCK lookup 
# tables to the context's search space
my $blocks1 = {
    some_block_1 => 'hello',
};
my $blocks2 = {
    some_block_2 => 'world',
};

ok( ! $context->template('some_block_1') );
$context->visit($blocks1);
ok(   $context->template('some_block_1') eq 'hello' );
ok( ! $context->template('some_block_2') );
$context->visit($blocks2);
ok(   $context->template('some_block_1') eq 'hello' );
ok(   $context->template('some_block_2') eq 'world' );
$context->leave();
ok(   $context->template('some_block_1') eq 'hello' );
ok( ! $context->template('some_block_2') );
$context->leave();
ok( ! $context->template('some_block_1') );
ok( ! $context->template('some_block_2') );

# test that reset() clears all blocks
$context->visit($blocks1);
ok(   $context->template('some_block_1') eq 'hello' );
ok( ! $context->template('some_block_2') );
$context->visit($blocks2);
ok(   $context->template('some_block_1') eq 'hello' );
ok(   $context->template('some_block_2') eq 'world' );
$context->reset();
ok( ! $context->template('some_block_1') );
ok( ! $context->template('some_block_2') );

#test_expect(\*DATA, $tt, &callsign);

__DATA__



__END__
Methods:
   template()  - ok
   plugin()
   filter()
   process()
   include()
   throw()
   catch()
   localise()/delocalise()
   visit()/leave()/reset - ok
