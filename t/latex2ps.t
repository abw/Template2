#============================================================= -*-perl-*-
#
# t/latex2ps.t
#
# Test the Latex filter with PS (PostScript) output. Because of likely
# variations in installed fonts etc, we don't verify the entire PS
# file. We simply make sure the filter runs without error and the
# first four characters of the output file have the correct value
# "%!PS".
#
# Written by Craig Barratt <craig@arraycomm.com>
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
$^W = 1;

my($LaTeXPath, $PdfLaTeXPath, $DviPSPath) = @{Template::Config->latexpaths()};

#
# We need a non-empty $LaTeXPath and $DviPSPath to convert to PS
#
if ( $LaTeXPath eq "" || $DviPSPath eq "" ) {
    exit(0);
}

test_expect(\*DATA, { FILTERS => {
                            head2hex => [\&head2hex_filter_factory, 1],
                        }
                    });

#
# Grab just the first $len bytes of the input, and optionall convert
# to a hex string if $hex is set
#
sub head2hex_filter_factory
{
    my($context, $len, $hex) = @_;

    return sub {
        my $text = shift;
        return $text if length $text < $len;
        $text = substr($text, 0, $len);
        $text =~ s/(.)/sprintf("%02x", ord($1))/eg if ( $hex );
        return $text;
    }
}

__END__
-- test --
[% out = FILTER latex("ps") -%]
\documentclass{article}
\begin{document}
\section{Introduction}
This is the introduction.
\end{document}
[% END; out | head2hex(4, 0) %]
-- expect --
%!PS
-- test --
[% TRY; FILTER latex("ps") -%]
\documentclass{article}
\begin{document}
\section{Introduction}
\badmacro
This is the introduction.
\end{document}
[% END; -%]
[% CATCH -%]
ERROR: [% error.type %] [% error.info %]
[% END -%]
-- expect --
ERROR: latex latex exited with errors:
! Undefined control sequence.
l.4 \badmacro
