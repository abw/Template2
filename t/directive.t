#============================================================= -*-perl-*-
#
# t/directive.t
#
# Test basic directive layout and processing options.
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
$^W = 1;

my $tt1 = Template->new();
my $tt2 = Template->new( PRE_CHOMP => 1 );
my $tt3 = Template->new( POST_CHOMP => 1 );

test_expect(\*DATA, [ tt => $tt1, pre => $tt2, post => $tt3 ], callsign);

__DATA__
#------------------------------------------------------------------------
# comments
#------------------------------------------------------------------------
-- test --
[%# this is a comment which should
    be ignored in totality
%]hello world
-- expect --
hello world

-- test -- 
[% # this is a one-line comment
   a
%]
-- expect --
alpha

-- test -- 
[% # this is a two-line comment
   a =
   # here's the next line
   b
-%]
[% a %]
-- expect --
bravo

-- test --
[% a = c   # this is a comment on the end of the line
   b = d   # so is this
-%]
a: [% a %]
b: [% b %]
-- expect --
a: charlie
b: delta

#------------------------------------------------------------------------
# manual chomping
#------------------------------------------------------------------------

-- test --
[% a %]
[% b %]
-- expect --
alpha
bravo

-- test --
[% a -%]
[% b %]
-- expect --
alphabravo

-- test --
[% a -%]
     [% b %]
-- expect --
alpha     bravo

-- test --
[% a %]
[%- b %]
-- expect --
alphabravo

-- test --
[% a %]
     [%- b %]
-- expect --
alphabravo

-- test --
start
[% a %]
[% b %]
end
-- expect --
start
alpha
bravo
end

-- test --
start
[%- a %]
[% b -%]
end
-- expect --
startalpha
bravoend

-- test --
start
[%- a -%]
[% b -%]
end
-- expect --
startalphabravoend

-- test --
start
[%- a %]
[%- b -%]
end
-- expect --
startalphabravoend

#------------------------------------------------------------------------
# PRE_CHOMP enabled 
#------------------------------------------------------------------------

-- test --
-- use pre --
start
[% a %]
mid
[% b %]
end
-- expect --
startalpha
midbravo
end

-- test --
start
     [% a %]
mid
	[% b %]
end
-- expect --
startalpha
midbravo
end

-- test --
start
[%+ a %]
mid
[% b %]
end
-- expect --
start
alpha
midbravo
end

-- test --
start
   [%+ a %]
mid
[% b %]
end
-- expect --
start
   alpha
midbravo
end

-- test --
start
   [%- a %]
mid
   [%- b %]
end
-- expect --
startalpha
midbravo
end

#------------------------------------------------------------------------
# POST_CHOMP enabled 
#------------------------------------------------------------------------

-- test --
-- use post --
start
[% a %]
mid
[% b %]
end
-- expect --
start
alphamid
bravoend

-- test --
start
     [% a %]
mid
	[% b %]        
end
-- expect --
start
     alphamid
	bravoend

-- test --
start
[% a +%]
mid
[% b %]
end
-- expect --
start
alpha
mid
bravoend

-- test --
start
[% a +%]   
[% b +%]
end
-- expect --
start
alpha   
bravo
end

-- test --
start
[% a -%]
mid
[% b -%]
end
-- expect --
start
alphamid
bravoend


