#============================================================= -*-Perl-*-
#
# Template::Context
#
# DESCRIPTION
#   Module defining a context in which a template document is processed.
#   This is the runtime processing interface through which templates 
#   can access the functionality of the Template Toolkit.
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

package Template::Context;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $AUTOLOAD );
use base qw( Template::Base );

use Template::Base;
use Template::Config;
use Template::Constants;
use Template::Exception;

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);



#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# template($name) 
#
# General purpose method to fetch a template and return it in compiled 
# form.  In the usual case, the $name parameter will be a simple string
# containing the name of a template (e.g. 'header').  It may also be 
# a reference to Template::Document object (or sub-class) or a Perl 
# sub-routine.  These are considered to be compiled templates and are
# returned intact.  Finally, it may be a reference to any other kind 
# of valid input source accepted by Template::Provider (e.g. scalar
# ref, glob, IO handle, etc).
#
# Templates may be cached at one of 3 different levels.  The internal
# BLOCKS member is a local cache which holds references to all
# template blocks used or imported via PROCESS since the context's
# reset() method was last called.  This is checked first and if the
# template is not found, the method then walks down the BLOCKSTACK
# list.  This contains references to the block definition tables in
# any enclosing Template::Documents that we're visiting (e.g. we've
# been called via an INCLUDE and we want to access a BLOCK defined in
# the template that INCLUDE'd us).  If nothing is defined, then we
# iterate through the LOAD_TEMPLATES providers list as a 'chain of 
# responsibility' (see Design Patterns) asking each object to fetch() 
# the template if it can.
#
# Returns the compiled template.  On error, undef is returned and 
# the internal ERROR value (read via error()) is set to contain an
# error message of the form "$name: $error".
#------------------------------------------------------------------------

sub template {
    my ($self, $name) = @_;
    my ($blocks, $defblocks, $provider, $template, $error);

    # references to Template::Document (or sub-class) objects objects, or
    # CODE references are assumed to be pre-compiled templates and are
    # returned intact
    return $name
	if UNIVERSAL::isa($name, 'Template::Document')
	    || ref($name) eq 'CODE';

    unless (ref $name) {
	# we first look in the BLOCKS hash for a BLOCK that may have 
	# been imported from a template (via PROCESS)
	return $template
	    if ($template = $self->{ BLOCKS }->{ $name });

	# the we iterate through the BLKSTACK list to see if any of the
	# Template::Documents we're visiting define this BLOCK
	foreach $blocks (@{ $self->{ BLKSTACK } }) {
	    return $template
		if $blocks && ($template = $blocks->{ $name });
	}
    }

    # finally we try the regular template providers which will 
    # handle references to files, text, etc., as well as templates
    # reference by name
    foreach my $provider (@{ $self->{ LOAD_TEMPLATES } }) {
	($template, $error) = $provider->fetch($name);
	return $template unless $error;
#	return $self->error($template)
	if ($error == Template::Constants::STATUS_ERROR) {
	    $self->throw($template) if ref $template;
	    $self->throw(Template::Constants::ERROR_FILE, $template);
	}
    }

#    return $self->error("$name: not found");
    $self->throw(Template::Constants::ERROR_FILE, "$name: not found");
}


#------------------------------------------------------------------------
# plugin($name, \@args)
#
# Calls on each of the LOAD_PLUGINS providers in turn to fetch() (i.e. load
# and instantiate) a plugin of the specified name.  Additional parameters 
# passed are propagated to the new() constructor for the plugin.  
# Returns a reference to a new plugin object or other reference.  On 
# error, undef is returned and the appropriate error message is set for
# subsequent retrieval via error().
#------------------------------------------------------------------------

sub plugin {
    my ($self, $name, $args) = @_;
    my ($provider, $plugin, $error);

    # request the named plugin from each of the LOAD_PLUGINS providers in turn
    foreach my $provider (@{ $self->{ LOAD_PLUGINS } }) {
	($plugin, $error) = $provider->fetch($name, $args, $self);
	return $plugin unless $error;
	if ($error == Template::Constants::STATUS_ERROR) {
	    $self->throw($plugin) if ref $plugin;
	    $self->throw(Template::Constants::ERROR_PLUGIN, $plugin);
	}
    }

    $self->throw(Template::Constants::ERROR_PLUGIN, "$name: plugin not found");
}


#------------------------------------------------------------------------
# filter($name, \@args, $alias)
#
# Similar to plugin() above, but querying the LOAD_FILTERS providers to 
# return filter instances.  An alias may be provided which is used to
# save the returned filter in a local cache.
#------------------------------------------------------------------------

sub filter {
    my ($self, $name, $args, $alias) = @_;
    my ($provider, $filter, $error);

    # use any cached version of the filter if no params provided
    return $filter 
	if ! $args && ! ref $name
	    && ($filter = $self->{ FILTER_CACHE }->{ $name });

    # request the named filter from each of the FILTERS providers in turn
    foreach my $provider (@{ $self->{ LOAD_FILTERS } }) {
	$filter = $name, last 
	    if ref $name;

	($filter, $error) = $provider->fetch($name, $args, $self);
	last unless $error;
	return $self->error($filter)
	    if $error == &Template::Constants::STATUS_ERROR;
    }

    return $self->error("$name: filter not found")
	unless $filter;

    # alias defaults to name if undefined
    $alias = $name
	unless defined($alias) or ref($name);

    # cache FILTER if alias is valid
    $self->{ FILTER_CACHE }->{ $alias } = $filter
	if $alias;

    return $filter;
}


#------------------------------------------------------------------------
# process($template, \%params)    [% PROCESS template   var = val, ... %]
#
# Processes the template named or referenced by the first parameter.
# The optional second parameter may reference a hash array of variable
# definitions.  These are set before the template is processed by calling
# update() on the stash.  Note that the context is not localised and 
# these, and any other variables set in the template will retain their
# new values after this method returns.
#
# Returns the output of processing the template.  Errors are thrown
# as Template::Exception objects via die().  
#------------------------------------------------------------------------

sub process {
    my ($self, $template, $params) = @_;
    my ($blocks, $output);
    my $name = $template;

    # request compiled template from cache 
    $template = $self->template($template);
#	|| die Template::Exception->new(&Template::Constants::ERROR_FILE, 
#				$self->{ _ERROR } || "$template: not found");

    # merge any local blocks defined in the Template::Document into our
    # local BLOCKS cache
    @{ $self->{ BLOCKS } }{ keys %$blocks } = values %$blocks
	if UNIVERSAL::isa($template, 'Template::Document')
	    && ($blocks = $template->blocks);

    # update stash with any new parameters passed
    $params ||= { };
    $params->{ component } = ref $template eq 'CODE' 
	? { ref $name ? () : ( name => $name, modtime => time() ) }
        : $template;
    $self->{ STASH }->update($params);
#	if $params;
    
    if (ref $template eq 'CODE') {
	$output = &$template($self);
    }
    elsif (ref $template) {
	$output = $template->process($self);
    }
    else {
	die "invalid template reference: $template\n";
    }

    if ($self->{ TRIM }) {
	for ($output) {
	    s/^\s+//;
	    s/\s+$//;
	}
    }
    
    return $output;
}


#------------------------------------------------------------------------
# include($template, \%params)    [% INCLUDE template   var = val, ... %]
#
# Similar to process() above but processing the template in a local 
# context.  Any variables passed by reference to a hash as the second
# parameter will be set before the template is processed and then 
# revert to their original values before the method returns.  Similarly,
# any changes made to non-global variables within the template will 
# persist only until the template is processed.
#
# Returns the output of processing the template.  Errors are thrown
# as Template::Exception objects via die().  
#------------------------------------------------------------------------

sub include {
    my ($self, $template, $params) = @_;
    my ($error, $blocks);
    my $output = '';
    my $name = $template;

    # request compiled template from cache 
    $template = $self->template($template);
#	|| die Template::Exception->new(&Template::Constants::ERROR_FILE, 
#			       $self->{ _ERROR } || "$template: not found" );

    # localise the variable stash with any parameters passed
    $params ||= { };
    $params->{ component } = ref $template eq 'CODE' 
	? { ref $name ? () : (name => $name, modtime => time()) }
        : $template;
    $self->{ STASH } = $self->{ STASH }->clone($params);

    eval {
	if (ref $template eq 'CODE') {
	    $output = &$template($self);
	}
	elsif (ref $template) {
	    $output = $template->process($self);
	}
	else {
	    die "invalid template reference: $template\n";
	}
    };
    $error = $@;

    $self->{ STASH } = $self->{ STASH }->declone();

    die $error if $error;

    if ($self->{ TRIM }) {
	for ($output) {
	    s/^\s+//;
	    s/\s+$//;
	}
    }

    return $output;
}


#------------------------------------------------------------------------
# insert($file)
#
# Insert the contents of a file without parsing.
#------------------------------------------------------------------------

sub insert {
    my ($self, $file) = @_;
    my ($text, $error);

    foreach my $provider (@{ $self->{ LOAD_TEMPLATES } }) {
	($text, $error) = $provider->load($file);
	return $text unless $error;
	if ($error == Template::Constants::STATUS_ERROR) {
	    $self->throw($text) if ref $text;
	    $self->throw(Template::Constants::ERROR_FILE, $text);
	}
    }

    $self->throw(Template::Constants::ERROR_FILE, "$file: not found");
}


#------------------------------------------------------------------------
# throw($type, $info, \$output)          [% THROW errtype "Error info" %]
#
# Throws a Template::Exception object by calling die().  This method
# may be passed a reference to an existing Template::Exception object;
# a single value containing an error message which is used to
# instantiate a Template::Exception of type 'undef'; or a pair of
# values representing the exception type and info from which a
# Template::Exception object is instantiated.  e.g.
#
#   $context->throw($exception);
#   $context->throw("I'm sorry Dave, I can't do that");
#   $context->throw('denied', "I'm sorry Dave, I can't do that");
#
# An optional third parameter can be supplied in the last case which 
# is a reference to the current output buffer containing the results
# of processing the template up to the point at which the exception 
# was thrown.  The RETURN and STOP directives, for example, use this 
# to propagate output back to the user, but it can safely be ignored
# in most cases.
# 
# This method rides on a one-way ticket to die() oblivion.  It does not 
# return in any real sense of the word, but should get caught by a 
# surrounding eval { } block (e.g. a BLOCK or TRY) and handled 
# accordingly, or returned to the caller as an uncaught exception.
#------------------------------------------------------------------------

sub throw {
    my ($self, $error, $info, $output) = @_;
    local $" = ', ';

    # die! die! die!
    if (UNIVERSAL::isa($error, 'Template::Exception')) {
#	print STDERR "throwing existing exception [@$error]\n";
	die $error;
    }
    elsif (defined $info) {
#	print STDERR "throwing new exception [$error] [$info]\n";
	die Template::Exception->new($error, $info, $output);
    }
    else {
	$error ||= '';
#	print STDERR "throwing an undefined exception [$error]\n";
	die Template::Exception->new('undef', $error, $output);
    }

    # not reached
}


#------------------------------------------------------------------------
# catch($error, \$output)
#
# Called by various directives after catching an error thrown via die()
# from within an eval { } block.  The first parameter contains the errror
# which may be a sanitized reference to a Template::Exception object
# (such as that raised by the throw() method above, a plugin object, 
# and so on) or an error message thrown via die from somewhere in user
# code.  The latter are coerced into 'undef' Template::Exception objects.
# Like throw() above, a reference to a scalar may be passed as an
# additional parameter to represent the current output buffer
# localised within the eval block.  As exceptions are thrown upwards
# and outwards from nested blocks, the catch() method reconstructs the
# correct output buffer from these fragments, storing it in the
# exception object for passing further onwards and upwards.
#
# Returns a reference to a Template::Exception object..
#------------------------------------------------------------------------

sub catch {
    my ($self, $error, $output) = @_;

    if (UNIVERSAL::isa($error, 'Template::Exception')) {
	$error->text($output) if $output;
	return $error;
    }
    else {
	return Template::Exception->new('undef', $error, $output);
    }
}


#------------------------------------------------------------------------
# localise(\%params)
# delocalise()
#
# The localise() method creates a local copy of the current stash,
# allowing the existing state of variables to be saved and later 
# restored via delocalise().
#
# A reference to a hash array may be passed containing local variable 
# definitions which should be added to the cloned namespace.  These 
# values persist until delocalisation.
#------------------------------------------------------------------------

sub localise {
    my $self = shift;
    $self->{ STASH } = $self->{ STASH }->clone(@_);
}

sub delocalise {
    my $self = shift;
    $self->{ STASH } = $self->{ STASH }->declone();
}


#------------------------------------------------------------------------
# visit($blocks)
#
# Each Template::Document calls the visit() method on the context
# before processing itself.  It passes a reference to the hash array
# of named BLOCKs defined within the document, allowing them to be 
# added to the internal BLKSTACK list which is subsequently used by
# template() to resolve templates.
# from a provider.
#------------------------------------------------------------------------

sub visit {
    my ($self, $blocks) = @_;
    unshift(@{ $self->{ BLKSTACK } }, $blocks)
}


#------------------------------------------------------------------------
# leave()
#
# The leave() method is called when the document has finished
# processing itself.  This removes the entry from the BLKSTACK list
# that was added visit() above.  For persistance of BLOCK definitions,
# the process() method (i.e. the PROCESS directive) does some extra
# magic to copy BLOCKs into a shared hash.
#------------------------------------------------------------------------

sub leave {
    my $self = shift;
    shift(@{ $self->{ BLKSTACK } });
}


#------------------------------------------------------------------------
# define_block($name, $block)
#
# Adds a new BLOCK definition to the local BLOCKS cache.  $block may
# be specified as a reference to a sub-routine or Template::Document
# object or as text which is compiled into a template.  Returns a true
# value (the $block reference or compiled block reference) if
# succesful or undef on failure.  Call error() to retrieve the
# relevent error message (i.e. compilation failure).
#------------------------------------------------------------------------

sub define_block {
    my ($self, $name, $block) = @_;
    $block = $self->template(\$block)
	|| return undef
	    unless ref $block;
    $self->{ BLOCKS }->{ $name } = $block;
}


#------------------------------------------------------------------------
# define_filter($name, $filter, $is_dynamic)
#
# Adds a new FILTER definition to the local FILTER_CACHE.
#------------------------------------------------------------------------

sub define_filter {
    my ($self, $name, $filter, $is_dynamic) = @_;
    my ($result, $error);
    $filter = [ $filter, 1 ] if $is_dynamic;

    foreach my $provider (@{ $self->{ LOAD_FILTERS } }) {
	($result, $error) = $provider->store($name, $filter);
	return 1 unless $error;
	$self->throw(&Template::Constants::ERROR_FILTER, $result)
	    if $error == &Template::Constants::STATUS_ERROR;
    }
    $self->throw(&Template::Constants::ERROR_FILTER, 
		 "FILTER providers declined to store filter $name");
}


#------------------------------------------------------------------------
# reset()
# 
# Reset the state of the internal BLOCKS hash to clear any BLOCK 
# definitions imported via the PROCESS directive.  Any original 
# BLOCKS definitions passed to the constructor will be restored.
#------------------------------------------------------------------------

sub reset {
    my ($self, $blocks) = @_;
    $self->{ BLKSTACK } = [ ];
    $self->{ BLOCKS   } = { %{ $self->{ INIT_BLOCKS } } };
}


#------------------------------------------------------------------------
# stash()
#
# Simple accessor methods to return the STASH values.  This is likely
# to be called quite often so we provide a direct method rather than
# relying on the slower AUTOLOAD.
#------------------------------------------------------------------------

sub stash {
    return $_[0]->{ STASH };
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides pseudo-methods for read-only access to various internal 
# members.  For example, templates(), plugins(), filters(),
# eval_perl(), load_perl(), etc.  These aren't called very often, or
# may never be called at all.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    my $result;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    warn "no such context method/member: $method\n"
	unless defined ($result = $self->{ uc $method });

    return $result;
}


#------------------------------------------------------------------------
# DESTROY
#
# Stash may contain references back to the Context via macro closures,
# etc.  This breaks the circular references. 
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    undef $self->{ STASH };
}



#========================================================================
#                     -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _init(\%config)
#
# Initialisation method called by Template::Base::new()
#------------------------------------------------------------------------

sub _init {
    my ($self, $config) = @_;
    my ($name, $item, $method, $block, $blocks);
    my @itemlut = ( 
	LOAD_TEMPLATES => 'provider',
	LOAD_PLUGINS   => 'plugins',
	LOAD_FILTERS   => 'filters' 
    );

    # LOAD_TEMPLATE, LOAD_PLUGINS, LOAD_FILTERS - lists of providers
    while (($name, $method) = splice(@itemlut, 0, 2)) {
	$item = $config->{ $name } 
	     || Template::Config->$method($config)
	     || return $self->error($Template::Config::ERROR);
	$self->{ $name } = ref $item eq 'ARRAY' ? $item : [ $item ];
    }

    # STASH
    $self->{ STASH } = $config->{ STASH } || do {
      	my $predefs  = $config->{ VARIABLES } 
		    || $config->{ PRE_DEFINE } 
		    || { };

	# hack to get stash to know about debug mode
	$predefs->{ _DEBUG } = $config->{ DEBUG } || 0;
	Template::Config->stash($predefs)
	    || return $self->error($Template::Config::ERROR);
    };

    # compile any template BLOCKS specified as text
    $blocks = $config->{ BLOCKS } || { };
    $self->{ INIT_BLOCKS } = $self->{ BLOCKS } = { 
	map {
	    $block = $blocks->{ $_ };
	    $block = $self->template(\$block)
		|| return undef
		    unless ref $block;
	    ($_ => $block);
	} 
	keys %$blocks
    };

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # RECURSION - flag indicating is recursion into templates is supported
    # EVAL_PERL - flag indicating if PERL blocks should be processed
    # TRIM      - flag to remove leading and trailing whitespace from output
    # BLKSTACK  - list of hashes of BLOCKs defined in current template(s)
    # CONFIG    - original configuration hash

    $self->{ RECURSION } = $config->{ RECURSION } || 0;
    $self->{ EVAL_PERL } = $config->{ EVAL_PERL } || 0;
    $self->{ TRIM      } = $config->{ TRIM } || 0;
    $self->{ BLKSTACK  } = [ ];
    $self->{ CONFIG    } = $config;

    return $self;
}


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the context object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $output = "$self\n";
    foreach my $pname (qw( LOAD_TEMPLATES LOAD_PLUGINS LOAD_FILTERS )) {
	foreach my $prov (@{ $self->{ $pname } }) {
	    $output .= $prov->_dump();
	}
    }
    return $output;
}


1;
