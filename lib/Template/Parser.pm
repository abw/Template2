#============================================================= -*-Perl-*-
#
# Template::Parser
#
# DESCRIPTION
#   This module implements a LALR(1) parser and assocated support 
#   methods to parse template documents into the appropriate "compiled"
#   format.  Much of the parser DFA code (see _parse() method) is based 
#   on Francois Desarmenien's Parse::Yapp module.  Kudos to him.
# 
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#   The following copyright notice appears in the Parse::Yapp 
#   documentation.  
#
#      The Parse::Yapp module and its related modules and shell
#      scripts are copyright (c) 1998 Francois Desarmenien,
#      France. All rights reserved.
#
#      You may use and distribute them under the terms of either
#      the GNU General Public License or the Artistic License, as
#      specified in the Perl README file.
# 
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Parser;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $ERROR );
use base qw( Template::Base );

use Template::Directive;
use Template::Grammar;

# parser state constants
use constant CONTINUE => 0;
use constant ACCEPT   => 1;
use constant ERROR    => 2;
use constant ABORT    => 3;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';


#========================================================================
#                        -- COMMON TAG STYLES --
#========================================================================

my $TAG_STYLE   = {
    'default'   => [ '\[%',    '%\]'    ],
    'template'  => [ '\[%',    '%\]'    ],
    'template1' => [ '[\[%]%', '%[\]%]' ],
    'metatext'  => [ '%%',     '%%'     ],
    'html'      => [ '<!--',   '-->'    ],
    'mason'     => [ '<%',     '>'      ],
    'asp'       => [ '<%',     '%>'     ],
    'php'       => [ '<\?',    '\?>'    ],
};


#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%config)
#
# Constructor method. 
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $config = ref $_[0] eq 'HASH' ? shift(@_) : { @_ };
    my ($tagstyle, $start, $end, $defaults, $grammar, $hash, $key, $udef);

    my $self = bless { 
	START_TAG   => undef,
	END_TAG     => undef,
	TAG_STYLE   => 'default',
	CASE        => 0,
	INTERPOLATE => 0,
	PRE_CHOMP   => 0,
	POST_CHOMP  => 0,
	V1DOLLAR    => 0,
	GRAMMAR     => undef,
	_ERROR      => '',
    }, $class;

    # update self with any relevant keys in config
    foreach $key (keys %$self) {
	$self->{ $key } = $config->{ $key } if defined $config->{ $key };
    }

    $grammar = $self->{ GRAMMAR } ||= do {
	require Template::Grammar;
	Template::Grammar->new();
    };
    $self->{ FACTORY } ||= 'Template::Directive';

    # determine START_TAG and END_TAG for specified (or default) TAG_STYLE
    $tagstyle = $self->{ TAG_STYLE } || 'default';
    return $class->error("Invalid tag style: $tagstyle")
	unless defined ($start = $TAG_STYLE->{ $tagstyle });
    ($start, $end) = @$start;

    $self->{ START_TAG } ||= $start;
    $self->{   END_TAG } ||= $end;

    # load grammar rules, states and lex table
    @$self{ qw( LEXTABLE STATES RULES ) } 
	= @$grammar{ qw( LEXTABLE STATES RULES ) };
    
    return $self;
}


#------------------------------------------------------------------------
# parse($text)
#
# Parses the text string, $text and returns a hash array representing
# the compiled template block(s) as Perl code, in the format expected
# by Template::Document.
#------------------------------------------------------------------------

sub parse {
    my $self = shift;
    my $text = shift;
    my ($tokens, $block);

    # store for blocks defined in the template (see define_block())
    my $defblock = $self->{ DEFBLOCK } = { };
    my $metadata = $self->{ METADATA } = [ ];

    $self->{ _ERROR }  = '';

    # split file into TEXT/DIRECTIVE chunks
    $tokens = $self->split_text($text)
	|| return undef;				    ## RETURN ##

    # parse chunks
    $block = $self->_parse($tokens)
	|| return undef;				    ## RETURN ##

    print STDERR "compiled main template document block:\n$block\n"
	if $DEBUG;

    return {
	BLOCK     => $block,
	DEFBLOCKS => $defblock,
	METADATA  => { @$metadata },
    };
}



#------------------------------------------------------------------------
# split_text($text)
#
# Split input template text into directives and raw text chunks.
#------------------------------------------------------------------------

sub split_text {
    my ($self, $text) = @_;
    my ($pre, $dir, $prelines, $dirlines, $postlines, $chomp, $tags, @tags);
    my ($start, $end, $prechomp, $postchomp, $interp ) = 
	@$self{ qw( START_TAG END_TAG PRE_CHOMP POST_CHOMP INTERPOLATE ) };

    my @tokens = ();
    my $line = 1;

    return \@tokens					    ## RETURN ##
	unless defined $text && length $text;

    # extract all directives from the text
    while ($text =~ s/
	   ^(.*?)               # $1 - start of line up to directive
	    (?:
		$start          # start of tag
		(.*?)           # $2 - tag contents
		$end            # end of tag
	    )
	    //sx) {

	($pre, $dir) = ($1, $2);
	$pre = '' unless defined $pre;
	$dir = '' unless defined $dir;
	
	$postlines = 0;                      # denotes lines chomped
	$prelines  = ($pre =~ tr/\n//);      # NULL - count only
	$dirlines  = ($dir =~ tr/\n//);      # ditto

	# the directive CHOMP options may modify the preceeding text
	for ($dir) {
	    # remove leading whitespace and check for a '-' chomp flag
	    s/^([-+\#])?\s*//s;
	    if ($1 && $1 eq '#') {
		# comment out entire directive
		$dir = '';
	    }
	    else {
		$chomp = ($1 && $1 eq '+') ? 0 : ($1 || $prechomp);

    		# chomp off whitespace and newline preceeding directive
    		$chomp and $pre =~ s/(\n|^)[ \t]*\Z//m
    		       and $1 eq "\n"
    		       and $prelines++;
	    }
    
	    # remove trailing whitespace and check for a '-' chomp flag
	    s/\s*([-+])?\s*$//s;
	    $chomp = ($1 && $1 eq '+') ? 0 : ($1 || $postchomp);

	    # only chomp newline if it's not the last character
	    $chomp and $text =~ s/^[ \t]*\n(.|\n)/$1/
		   and $postlines++;
	}

	# any text preceeding the directive can now be added
	if (length $pre) {
	    push(@tokens, $interp
		 ? [ $pre, $line, 'ITEXT' ]
		 : ('TEXT', $pre) );
	    $line += $prelines;
	}
	
	# and now the directive, along with line number information
	if (length $dir) {
	    # the TAGS directive is a compile-time switch
	    if ($dir =~ /TAGS\s+(.*)/i) {
		my @tags = split(/\s+/, $1);
		if (scalar @tags > 1) {
		    ($start, $end) = map { quotemeta($_) } @tags;
		}
		elsif ($tags = $TAG_STYLE->{ $tags[0] }) {
		    ($start, $end) = @$tags;
		}
		else {
		    warn "invalid TAGS style: $tags[0]\n";
		}
	    }
	    else {
		# DIRECTIVE is pushed as [ $dirtext, $line_no(s), \@tokens ]
		push(@tokens, [ $dir, 
				($dirlines 
				 ? sprintf("%d-%d", $line, $line + $dirlines)
				 : $line),
				$self->tokenise_directive($dir) ]);
	    }
	}

	# update line counter to include directive lines and any extra
	# newline chomped off the start of the following text
	$line += $dirlines + $postlines;
    }

    # anything remaining in the string is plain text 
    push(@tokens, $interp 
	 ? [ $text, $line, 'ITEXT' ]
	 : ( 'TEXT', $text) )
	if length $text;

    return \@tokens;					    ## RETURN ##
}



#------------------------------------------------------------------------
# interpolate_text($text, $line)
#
# Examines $text looking for any variable references embedded like
# $this or like ${ this }.
#------------------------------------------------------------------------

sub interpolate_text {
    my ($self, $text, $line) = @_;
    my @tokens  = ();
    my ($pre, $var, $dir);


    while ($text =~ 
	   /
	   ( (?: \\. | [^\$] )+ )   # escaped or non-'$' character [$1]
	   | 
	   ( \$ (?:		    # embedded variable	           [$2]
	     (?: \{ ([^\}]*) \} )   # ${ ... }                     [$3]
	     |
	     ([\w\.]+)		    # $word                        [$4]
	     )
	   )
	/gx) {
    
	($pre, $var, $dir) = ($1, $3 || $4, $2);

	# preceeding text
	if ($pre) {
	    $line += $pre =~ tr/\n//;
	    $pre =~ s/\\\$/\$/g;
	    push(@tokens, 'TEXT', $pre);
	}
	# $variable reference
        if ($var) {
	    $line += $dir =~ tr/\n/ /;
	    push(@tokens, [ $dir, $line, $self->tokenise_directive($var) ]);
	}
	# other '$' reference - treated as text
	elsif ($dir) {
	    $line += $dir =~ tr/\n//;
	    push(@tokens, 'TEXT', $dir);
	}
    }

    return \@tokens;
}



#------------------------------------------------------------------------
# tokenise_directive($text)
#
# Called by the private _parse() method when it encounters a DIRECTIVE
# token in the list provided by the split_text() or interpolate_text()
# methods.  The directive text is passed by parameter.
#
# The method splits the directive into individual tokens as recognised
# by the parser grammar (see Template::Grammar for details).  It
# constructs a list of tokens each represented by 2 elements, as per
# split_text() et al.  The first element contains the token type, the
# second the token itself.
#
# The method tokenises the string using a complex (but fast) regex.
# For a deeper understanding of the regex magic at work here, see
# Jeffrey Friedl's excellent book "Mastering Regular Expressions",
# from O'Reilly, ISBN 1-56592-257-3
#
# Returns a reference to the list of chunks (each one being 2 elements) 
# identified in the directive text.  On error, the internal _ERROR string 
# is set and undef is returned.
#------------------------------------------------------------------------

sub tokenise_directive {
    my ($self, $text, $line) = @_;
    my ($token, $uctoken, $type, $lookup);
    my ($lextable, $case) = @$self{ qw( LEXTABLE CASE ) };
    my @tokens = ( );

    while ($text =~ 
	    / 
		# strip out any comments
	        (\#[^\n]*)
	   |
		# a quoted phrase matches in $3
		(["'])                   # $2 - opening quote, " or '
		(                        # $3 - quoted text buffer
		    (?:                  # repeat group (no backreference)
			\\\\             # an escaped backslash \\
		    |                    # ...or...
			\\\2             # an escaped quote \" or \' (match $1)
		    |                    # ...or...
			.                # any other character
		    )*?                  # non-greedy repeat
		)                        # end of $3
		\2                       # match opening quote
	    |
		# an unquoted number matches in $4
		(-?\d+(?:\.\d+)?)       # numbers
	    |
		# filename matches in $5
	    	( \/?\w+(?:(?:\/|::)\w*)+ | \/\w+)
	    |
		# an identifier matches in $6
		(\w+)                    # variable identifier
	    |   
		# an unquoted word or symbol matches in $7
		(   [(){}\[\]:;,\/\\]    # misc parenthesis and symbols
#		|   \->                  # arrow operator (for future?)
		|   \+\-\*               # math operations
		|   \$\{?                # dollar with option left brace
		|   =>			 # like '='
		|   [=!<>]?= | [!<>]     # eqality tests
		|   &&? | \|\|?          # boolean ops
		|   \.\.?                # n..n sequence
 		|   \S+                  # something unquoted
		)                        # end of $7
	    /gmxo) {

	# ignore comments to EOL
	next if $1;

	# quoted string
	if (defined ($token = $3)) {
            # double-quoted string may include $variable references
	    if ($2 eq '"') {
	        if ($token =~ /[\$\\]/) {
		    $type = 'QUOTED';
		    # unescape " and \ but leave \$ escaped so that 
		    # interpolate_text() doesn't incorrectly treat it
		    # as a variable reference
		    $token =~ s/\\([\\"])/$1/g;
		    $token =~ s/\\n/\n/g;
		    push(@tokens, ('"') x 2,
				  @{ $self->interpolate_text($token) },
				  ('"') x 2);
		    next;
		}
                else {
	            $type = 'LITERAL';
		    $token =~ s['][\\']g;
		    $token = "'$token'";
		}
	    } 
	    else {
		$type = 'LITERAL';
		$token = "'$token'";
	    }
	}
	# number
	elsif (defined ($token = $4)) {
	    $type = 'NUMBER';
	}
	elsif (defined($token = $5)) {
	    $type = 'FILENAME';
	}
	elsif (defined($token = $6)) {
	    # reserved words may be in lower case unless case sensitive
	    $uctoken = $case ? $token : uc $token;
	    if (defined ($type = $lextable->{ $uctoken })) {
		$token = $uctoken;
	    }
	    else {
		$type = 'IDENT';
	    }
	}
	elsif (defined ($token = $7)) {
	    # reserved words may be in lower case unless case sensitive
	    $uctoken = $case ? $token : uc $token;
	    unless (defined ($type = $lextable->{ $uctoken })) {
		$type = 'UNQUOTED';
	    }
	}

	push(@tokens, $type, $token);

#	print(STDERR " +[ $type, $token ]\n")
#	    if $DEBUG;
    }

#    print STDERR "tokenise directive() returning:\n  [ @tokens ]\n"
#	if $DEBUG;

    return \@tokens;					    ## RETURN ##
}


#------------------------------------------------------------------------
# define_block($name, $block)
#
# Called by the parser 'defblock' rule when a BLOCK definition is 
# encountered in the template.  The name of the block is passed in the 
# first parameter and a reference to the compiled block is passed in
# the second.  This method stores the block in the $self->{ DEFBLOCK }
# hash which has been initialised by parse() and will later be used 
# by the same method to call the store() method on the calling cache
# to define the block "externally".
#------------------------------------------------------------------------

sub define_block {
    my ($self, $name, $block) = @_;
    my $defblock = $self->{ DEFBLOCK } 
        || return undef;

    print STDERR "compiled block '$name':\n$block\n"
	if $DEBUG;

    $defblock->{ $name } = $block;
    
    return undef;
}


#------------------------------------------------------------------------
# add_metadata(\@setlist)
#------------------------------------------------------------------------

sub add_metadata {
    my ($self, $setlist) = @_;
    my $metadata = $self->{ METADATA } 
        || return undef;

    push(@$metadata, @$setlist);
    
    return undef;
}


#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _parse(\@tokens)
#
# Parses the list of input tokens passed by reference and returns a 
# Template::Directive::Block object which contains the compiled 
# representation of the template. 
#
# This is the main parser DFA loop.  See embedded comments for 
# further details.
#
# On error, undef is returned and the internal _ERROR field is set to 
# indicate the error.  This can be retrieved by calling the error() 
# method.
#------------------------------------------------------------------------

sub _parse {
    my ($self, $tokens) = @_;
    my ($token, $value, $text, $line, $inperl);
    my ($state, $stateno, $status, $action, $lookup, $coderet, @codevars);
    my ($lhs, $len, $code);	    # rule contents
    my $stack = [ [ 0, undef ] ];   # DFA stack

# DEBUG
#   local $" = ', ';

    # retrieve internal rule and state tables
    my ($states, $rules) = @$self{ qw( STATES RULES ) };

    # call the grammar set_factory method to install emitter factory
    $self->{ GRAMMAR }->install_factory($self->{ FACTORY });

    $line = $inperl = 0;
    $self->{ LINE   } = \$line;
    $self->{ INPERL } = \$inperl;

    $status = CONTINUE;

    while(1) {
	# get state number and state
	$stateno =  $stack->[-1]->[0];
	$state   = $states->[$stateno];

	# see if any lookaheads exist for the current state
	if (exists $state->{'ACTIONS'}) {

	    # get next token and expand any directives (i.e. token is an 
	    # array ref) onto the front of the token list
	    while (! defined $token && @$tokens) {
		$token = shift(@$tokens);
		if (ref $token) {
		    ($text, $line, $token) = @$token;
		    if (ref $token) {
			unshift(@$tokens, @$token, (';') x 2);
			$token = undef;  # force redo
		    }
		    elsif ($token eq 'ITEXT') {
			if ($inperl) {
			    # don't perform interpolation in PERL blocks
			    $token = 'TEXT';
			    $value = $text;
			}
			else {
			    unshift(@$tokens, 
				    @{ $self->interpolate_text($text, $line) });
			    $token = undef; # force redo
			}
		    }
		}
		else {
		    $value = shift(@$tokens);
		}
	    };
	    # clear undefined token to avoid 'undefined variable blah blah'
	    # warnings and let the parser logic pick it up in a minute
	    $token = '' unless defined $token;

	    # get the next state for the current lookahead token
	    $action = defined ($lookup = $state->{'ACTIONS'}->{ $token })
	              ? $lookup
		      : defined ($lookup = $state->{'DEFAULT'})
		        ? $lookup
		        : undef;
	}
	else {
	    # no lookahead actions
	    $action = $state->{'DEFAULT'};
	}

	# ERROR: no ACTION
	last unless defined $action;

	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# shift (+ive ACTION)
	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if ($action > 0) {
	    push(@$stack, [ $action, $value ]);
	    $token = $value = undef;
	    redo;
	};

	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# reduce (-ive ACTION)
	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	($lhs, $len, $code) = @{ $rules->[ -$action ] };

	# no action imples ACCEPTance
	$action
	    or $status = ACCEPT;

	# use dummy sub if code ref doesn't exist
	$code = sub { $_[1] }
	    unless $code;

	@codevars = $len
		?   map { $_->[1] } @$stack[ -$len .. -1 ]
		:   ();

	$coderet = &$code( $self, @codevars );

	# reduce stack by $len
	splice(@$stack, -$len, $len);

	# ACCEPT
	return $coderet					    ## RETURN ##
	    if $status == ACCEPT;

	# ABORT
	return undef					    ## RETURN ##
	    if $status == ABORT;

	# ERROR
	last 
	    if $status == ERROR;
    }
    continue {
	push(@$stack, [ $states->[ $stack->[-1][0] ]->{'GOTOS'}->{ $lhs }, 
	      $coderet ]), 
    }

    # ERROR						    ## RETURN ##
    return $self->_parse_error('unexpected end of input')
	unless defined $value;

    # munge text of last directive to make it readable
#    $text =~ s/\n/\\n/g;

    return $self->_parse_error("unexpected end of directive", $text)
	if $value eq ';';   # end of directive SEPARATOR

    return $self->_parse_error("unexpected token ($value)", $text);
}



#------------------------------------------------------------------------
# _parse_error($msg, $dirtext)
#
# Method used to handle errors encountered during the parse process
# in the _parse() method.  
#------------------------------------------------------------------------

sub _parse_error {
    my ($self, $msg, $text) = @_;
    my $line = $self->{ LINE };
    $line = ref($line) ? $$line : $line;
    $line = 'unknown' unless $line;

    $msg .= "\n  [% $text %]"
	if defined $text;

    return $self->error("line $line: $msg");
}


#------------------------------------------------------------------------
# _dump()
# 
# Debug method returns a string representing the internal state of the 
# object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $output = "$self:\n";
    foreach my $key (qw( START_TAG END_TAG TAG_STYLE CASE INTERPOLATE 
			 PRE_CHOMP POST_CHOMP V1DOLLAR ) ) {
	
	$output .= sprintf("%-12s => %s\n", $key, $self->{ $key });
    }
    return $output;
}
    


1;

