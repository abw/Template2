#============================================================= -*-Perl-*-
#
# Template::Plugin::Math
#
# DESCRIPTION
#   Plugin implementing numerous mathematical functions.
#
# AUTHORS
#   Andy Wardley   <abw@kfs.org>
#   ...your name here...
#
# COPYRIGHT
#   Copyright (C) 2002 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#============================================================================

package Template::Plugin::Math;

require 5.004;

use strict;
use vars qw( $VERSION $AUTOLOAD );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#------------------------------------------------------------------------
# new($context, \%config)
#
# This constructor method creates a simple, empty object to act as a 
# receiver for future object calls.  No doubt there are many interesting
# configuration options that might be passed, but I'll leave that for 
# someone more knowledgable in these areas to contribute...
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $config) = @_;
    $config ||= { };

    bless {
	%$config,
    }, $class;
}

sub abs   { shift; CORE::abs($_[0]);          }
sub atan2 { shift; CORE::atan2($_[0], $_[0]); } # prototyped (ugg)
sub cos   { shift; CORE::cos($_[0]);          }
sub exp   { shift; CORE::exp($_[0]);          }
sub hex   { shift; CORE::hex($_[0]);          }
sub int   { shift; CORE::int($_[0]);          }
sub log   { shift; CORE::log($_[0]);          }
sub oct   { shift; CORE::oct($_[0]);          }
sub rand  { shift; CORE::rand($_[0]);         }
sub sin   { shift; CORE::sin($_[0]);          }
sub sqrt  { shift; CORE::sqrt($_[0]);         }
sub srand { shift; CORE::srand($_[0]);        }

# Use the Math::TrulyRandom module
# XXX This is *sloooooooowwwwwwww*
sub truly_random {
    eval { require Math::TrulyRandom; }
         or die(Template::Exception->new("plugin",
            "Can't load Math::TrulyRandom"));
    return Math::TrulyRandom::truly_random_value();
}

eval {
    require Math::Trig;
    no strict qw(refs);
    for my $trig_func (@Math::Trig::EXPORT) {
        my $sub = Math::Trig->can($trig_func);
        *{$trig_func} = sub { shift; &$sub(@_) };
    }
};

# To catch errors from a missing Math::Trig
sub AUTOLOAD { return; }

1;

__END__

=head1 NAME

Template::Plugin::Math - Plugin providing mathematical functions

=head1 SYNOPSIS

    [% USE Math %]

    [% Math.sqrt(9) %]

=head1 DESCRIPTION

The Math plugin provides numerous mathematical functions for use within
templates.

=head1 METHODS

=head2 sqrt($n)

Returns the square root of a number.

=head1 AUTHORS

Andy Wardley E<lt>abw@kfs.orgE<gt> provided the original skeleton
plugin which was then fleshed out by Darren Chamberlain
E<lt>dlc@users.sourceforge.netE<gt> one night when he had nothing
bettwe to dp

=head1 VERSION

This is version 0.01 of the Template::Plugin::Math module.

=head1 COPYRIGHT

  Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>
