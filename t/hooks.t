#============================================================= -*-perl-*-
#
# t/hooks.t
#
# Test that PRE_COMPILE_HOOK works correctly.
#
# Written by Andy Wardley <abw@wardley.org>
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
$^W = 1;

$Template::Test::DEBUG = 0;

my $dir    = -d 't' ? 't/test' : 'test';
my $config = {
    INCLUDE_PATH => "$dir/src:$dir/lib",
    START_TAG => quotemeta('[['),
    END_TAG   => quotemeta(']]'),
    POST_CHOMP => 1,
    PRE_COMPILE_HOOK => \&my_pre_compile_hook,
};

sub my_pre_compile_hook {
    my ( $data, $filename, $name ) = @_;

    return "[<$name>$data]";
}

my $replace = {
    a => 'alpha',
    b => 'bravo',
};

test_expect(\*DATA, $config, $replace);

__DATA__

-- test --
A latex ams article

[[ INCLUDE texfile1
   intro_sec='Introduction' ]]

From \eqref{eq:lib:texfile1:1} it follows that ...
-- expect --
A latex ams article

[<texfile1>\section{Introduction}
The equation ...
\begin{align}
  \label{eq:1}
  \phi(\delta, \tau) =
\end{align}
[<texfile2>\subsection{Another section}
\begin{align}
  \label{eq:1}
  y = x^2
\end{align}
]End
]
From \eqref{eq:lib:texfile1:1} it follows that ...
