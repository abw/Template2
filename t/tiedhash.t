#============================================================= -*-perl-*-
#
# t/tiedhash.t
#
# Template script testing variable via a tied hash.
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
use lib qw( blib/lib blib/arch lib ../blib/lib ../blib/arch ../lib );
use Template::Test;
use Template::Stash;
$^W = 1;

eval {
    require Template::Stash::XS;
};
if ($@) {
    warn $@;
    skip_all('cannot load Template::Stash::XS');
}

#print "stash: $Template::Config::STASH\n";
#$Template::Config::STASH = 'Template::Stash::XS';

#------------------------------------------------------------------------
package My::Tied::Hash;
use base qw( Tie::Hash );
use vars qw( $AUTOLOAD );

sub new {
    my ($class, $meths) = @_;
    my %hash;
    tie %hash, $class, $meths;
    return \%hash;
}

sub TIEHASH {
    my ($class, $meths) = @_;
    bless $meths, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    my $action = $self->{ FETCH } || return undef;
    &$action($key);
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $action = $self->{ STORE } || return undef;
    &$action($key, $value);
}

# sub DELETE   { }
# sub CLEAR    { }
# sub EXISTS   { }
# sub FIRSTKEY { }
# sub NEXTKEY  { }

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    my $action = $self->{ $item } || return undef;
    &$action(@_);
}

#------------------------------------------------------------------------
package main;

my $DEBUG = grep(/-d/, @ARGV);
my $data = callsign();
$data->{ zero } = 0;
$data->{ one  } = 1;

my $hash = My::Tied::Hash->new({
    FETCH => sub { my $key = shift; 
		   print "FETCH($key)\n" if $DEBUG;
		   $data->{ $key };
	       },
    STORE => sub { my ($key, $val) = @_; 
		   print "STORE($key, $val)\n" if $DEBUG;
		   $data->{ $key } = $val;
	       },
});

#------------------------------------------------------------------------

my $stash_perl = Template::Stash->new({ hash => $hash });
my $stash_xs   = Template::Stash::XS->new({ hash => $hash });
my $tt = [
    perl => Template->new( STASH => $stash_perl ),
    xs   => Template->new( STASH => $stash_xs ),
];
test_expect(\*DATA, $tt);

__DATA__
-- test --
[% hash.a %]
-- expect --
alpha

-- test --
[% hash.b %]
-- expect --
bravo

-- test --
ready
set:[% hash.c = 'cosmos' %]
go:[% hash.c %]
-- expect --
ready
set:
go:cosmos

-- test --
[% hash.foo.bar = 'one' -%]
[% hash.foo.bar %]
-- expect --
one

-- test --
-- use xs --
[% hash.a %]
-- expect --
alpha

-- test --
[% hash.b %]
-- expect --
bravo

-- test --
ready
set:[% hash.c = 'crazy' %]
go:[% hash.c %]
-- expect --
ready
set:
go:crazy

-- test --
[% hash.wiz = 'woz' -%]
[% hash.wiz %]
-- expect --
woz

-- test --
[% DEFAULT hash.zero = 'nothing';
   hash.zero
%]
-- expect --
nothing

-- test --
[% DEFAULT hash.one = 'solitude';
   hash.one
%]
-- expect --
1


