#================================================================= -*-Perl-*- 
#
# Template::Namespace::Constants
#
# DESCRIPTION
#   Plugin compiler module for performing constant folding at compile time
#   on variables in a particular namespace.
#
# AUTHOR
#   Andy Wardley   <abw@andywardley.com>
#
# COPYRIGHT
#   Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Namespace::Constants;

use strict;
use Template::Base;
use Template::Config;
use Template::Stash;
use Template::Exception;

use base qw( Template::Base );
use vars qw( $VERSION $DEBUG );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;


sub _init {
    my ($self, $config) = @_;
    $self->{ STASH } = Template::Config->stash($config)
	|| return $self->error(Template::Config->error());
    return $self;
}



#------------------------------------------------------------------------
# ident(\@ident)                                             foo.bar(baz)
#------------------------------------------------------------------------

sub ident {
    my ($self, $ident) = @_;
    my $nelems = @$ident / 2;
    my ($e, $result);
    local $" = ', ';

    print STDERR "constant ident [ @$ident ] " if $DEBUG;

    foreach $e (0..$nelems-1) {
	# node name must be a constant
	die "cannot fold constant ", $ident->[$e * 2], "\n"
	    unless $ident->[$e * 2] =~ s/^'(.+)'$/$1/s;

	# if args is non-zero then it must be eval'ed 
	if ($ident->[$e * 2 + 1]) {
	    my $args = $ident->[$e * 2 + 1];
	    my $comp = eval "$args";
	    die "cannot compile constant arguments: $args\n" if $@;
	    print STDERR "($args) " if $comp && $DEBUG;
	    $ident->[$e * 2 + 1] = $comp;
	}
    }

    $result = $self->{ STASH }->get($ident);
    die "undefined constant [ @$ident ]\n" unless defined $result;

    $result =~ s/'/\\'/;

    print STDERR "=> '$result'\n" if $DEBUG;

    return "'$result'";

}

1;

__END__

