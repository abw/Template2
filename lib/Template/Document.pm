#============================================================= -*-Perl-*-
#
# Template::Document
#
# DESCRIPTION
#   Module defining a class of objects which encapsulate compiled
#   templates, storing additional block definitions and metadata 
#   as well as the compiled Perl sub-routine representing the main
#   template content.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
# 
#----------------------------------------------------------------------------
#
# $Id$
#
#============================================================================

package Template::Document;

require 5.004;

use strict;
use vars qw( $VERSION $ERROR $DEBUG $AUTOLOAD );
use base qw( Template::Base );
use Template::Constants;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);


#========================================================================
#                      ----- PACKAGE SUBS -----
#========================================================================

sub write_perl_file {
    my ($file, $content) = @_;
    my ($block, $defblocks, $metadata) = 
	@$content{ qw( BLOCK DEFBLOCKS METADATA ) };
    my $pkg = __PACKAGE__;

    $defblocks = join('', 
		      map { "'$_' => $defblocks->{ $_ },\n" }
		      keys %$defblocks);

    $metadata = join('', 
		       map { 
			   my $x = $metadata->{ $_ }; 
			   $x =~ s/['\\]/\\$1/g; 
			   "'$_' => '$x',";
		       } keys %$metadata);

    local *CFH;
    open(CFH, ">$file") or do {
	$ERROR = $!;
	return undef;
    };

    print CFH  <<EOF;
bless {
$metadata
_HOT       => 0,
_BLOCK     => $block,
_DEFBLOCKS => {
$defblocks
},
}, $pkg;
EOF
    close(CFH);

    return 1;
}

		
#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new($block, \%defblocks, \%metadata))
#
# Creates a new self-contained Template::Document object which 
# encapsulates a compiled Perl sub-routine, $block, any additional 
# BLOCKs defined within the document ($defblocks, also Perl sub-routines)
# and additional $metadata about the document.
#------------------------------------------------------------------------

sub new {
    my ($class, $block, $defblocks, $metadata) = @_;
    $defblocks ||= { };
    $metadata  ||= { };

    # evaluate Perl code in $block to create sub-routine reference if necessary
    unless (ref $block) {
#	print "compiling BLOCK: $block\n";
	$block = eval $block;
	return $class->error($@)
	    if $@;
    }

    # same for any additional BLOCK definitions
    @$defblocks{ keys %$defblocks } = 
	map { ref($_) ? $_ : (eval($_) or return $class->error($@)) } 
        values %$defblocks;

#    print "BLOCK: $block\nDEFBLOCKS: ", (map { "  $_ => $defblocks->{ $_ }\n" }
#					 keys %$defblocks), "\n";

    bless {
	%$metadata,
	_BLOCK     => $block,
	_DEFBLOCKS => $defblocks,
	_HOT       => 0,
    }, $class;
}


#------------------------------------------------------------------------
# block()
#
# Returns a reference to the internal sub-routine reference, _BLOCK, 
# that constitutes the main document template.
#------------------------------------------------------------------------

sub block {
    return $_[0]->{ _BLOCK };
}


#------------------------------------------------------------------------
# blocks()
#
# Returns a reference to a hash array containing any BLOCK definitions 
# from the template.  The hash keys are the BLOCK nameand the values
# are references to Template::Document objects.  Returns 0 (# an empty hash)
# if no blocks are defined.
#------------------------------------------------------------------------

sub blocks {
    return $_[0]->{ _DEFBLOCKS };
}


#------------------------------------------------------------------------
# process($context)
#
# Process the document in a particular context.  Checks for recursion,
# registers the document with the context via visit(), processes itself,
# and then unwinds with a large gin and tonic.  Errors are handled, output
# is TRIMmed if required, etc.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $defblocks = $self->{ _DEFBLOCKS };
    my $output;


    # check we're not already visiting this template
    return $context->throw(Template::Constants::ERROR_FILE, 
			   "recursion into '$self->{ name }'")
	if $self->{ _HOT } && ! $context->{ RECURSION };   ## RETURN ##

    $context->visit($defblocks);
    $self->{ _HOT } = 1;
    eval {
	my $block = $self->{ _BLOCK };
	$output = &$block($context);
    };
    $self->{ _HOT } = 0;
    $context->leave();

    die $context->catch($@)
	if $@;
	
    if ($context->{ TRIM }) {
	for ($output) {
	    s/^\s+//;
	    s/\s+$//;
	}
    }

    return $output;
}


#------------------------------------------------------------------------
# as_perl()
#
# Returns a representation of the compiled template in Perl code.  Relies
# on PERL blocks being passed to the constructor.
#------------------------------------------------------------------------

sub as_perl {
    my $self = shift;
    my $class = ref $self;
    return <<EOF;
## NOTE: persistant templates don't work just yet
bless { 
    _BLOCK     => sub { return 'persistance not yet fully implemented' },
    _DEFBLOCKS => { },
    _HOT       => 0,
}, '$class';
EOF
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides pseudo-methods for read-only access to various internal 
# members. 
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    return $self->{ $method };
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $dblks;
    my $output = "$self : $self->{ name }\n";

    $output .= "BLOCK: $self->{ _BLOCK }\nDEFBLOCKS:\n";

    if ($dblks = $self->{ _DEFBLOCKS }) {
	foreach my $b (keys %$dblks) {
	    $output .= "    $b: $dblks->{ $b }\n";
	}
    }

    return $output;
}
    
1;


__END__

=head1 NAME

Template::Document - template object

=head1 SYNOPSIS

    use Template::Document;

    $doc = Template::Document->new(\&template, \%metadata);

=head1 DESCRIPTION

This module defines an object class whose instances represent compiled
template documents.  The Template::Parser module creates a
Template::Document instance to encapsulate a template as it is compiled
The template content itself should be passed to the constructor
as a reference to a sub-routine.  The Template::Document object simply
stores this reference internally and then calls it when its
process($context) method is invoked.  The sub-routine should expect a
Template::Context reference as its only parameter and should return
its output or raise an error by throwing a Template::Exception object
via C<die()> or through C<$context->throw()>.

    my $doc = Template::Document->new(
	sub { 
	    my $context = shift;
	    my $stash   = $context->stash();
	    my $foo     = $stash->get('foo') 
		|| $context->throw('nofoo', "'foo' is not defined);
	    
	    return "The value of foo is $foo";
	}
    );

    my $context = Template::Context->new(...)

    print $doc->process($context);

Additional parameters passed to the constructor are treated as named
metadata items.  These are also stored internally and available via an
AUTOLOAD method.

    my $doc = Template::Document->new(\&mytemplate, 
				      author  => 'Andy Wardley',
				      version => 3.14 );

    print "version ", $doc->version, " by ", $doc->author, "\n";

Metadata items are accessible in templates via the 'template' variable
which contains a reference to the parent Template::Document object,
where 'parent' defines the outermost template being processed.

    [% template.author %]

The BLOCKS parameter may be provided and should contain a reference to
a hash array of other Template::Document objects or sub-routines,
representing any additional BLOCK definitions within the template
source file.

    my $hdr = Template::Document->new(\&myheader);
    my $ftr = sub { my $context = shift; return "Template Output" };

    my $doc = Template::Document->new(\&mytemplate,
				      BLOCKS => {
				          header => $hdr,
				          footer => $ftr,
				      },
				      author  => 'Andy Wardley',
				      version => 3.14 );

Template::Document objects are usually created by the Template::Parser
but can be manually instantiated or sub-classed to provide custom
template components.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>,
L<Template::Parser|Template::Parser>

=cut




