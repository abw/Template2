#============================================================= -*-perl-*-
#
# Template
#
# DESCRIPTION
#   Module implementing a simple, user-oriented front-end to the Template 
#   Toolkit.
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
#------------------------------------------------------------------------
#
#   $Id$
#
#========================================================================
 
package Template;
use base qw( Template::Base );

require 5.005;

use strict;
use vars qw( $VERSION $AUTOLOAD $ERROR $DEBUG );
use Template::Base;
use Template::Config;
use Template::Provider;  
use Template::Service;
use Template::Utils;
#use Template::Parser;    # autoloaded on demand

## This is the main version number for the Template Toolkit.
## It is extracted by ExtUtils::MakeMaker and inserted in various places.
$VERSION     = '1.52';
$ERROR       = '';
$DEBUG       = 0;


#------------------------------------------------------------------------
# process($input, \%replace, $output)
#
# Main entry point for the Template Toolkit.  The Template module 
# delegates most of the processing effort to the underlying SERVICE
# object, an instance of the Template::Service class.  
#------------------------------------------------------------------------

sub process {
    my ($self, $template, $vars, $outstream) = @_;
    my ($output, $error);

    $output = $self->{ SERVICE }->process($template, $vars);
    
    if (defined $output) {
	$outstream ||= $self->{ OUTPUT };
	unless (ref $outstream) {
	    my $outpath = $self->{ OUTPUT_PATH };
	    $outstream = "$outpath/$outstream" if $outpath;
	}	

	# send processed template to output stream, checking for error
	return ($self->error($error))
	    if ($error = &Template::Utils::output($outstream, $output));

	return 1;
    }
    else {
	return $self->error($self->{ SERVICE }->error);
    }
}


#------------------------------------------------------------------------
# service()
#
# Returns a reference to the the internal SERVICE object which handles
# all requests for this Template object
#------------------------------------------------------------------------

sub service {
    my $self = shift;
    return $self->{ SERVICE };
}


#------------------------------------------------------------------------
# context()
#
# Returns a reference to the the CONTEXT object withint the SERVICE 
# object.
#------------------------------------------------------------------------

sub context {
    my $self = shift;
    return $self->{ SERVICE }->{ CONTEXT };
}


#========================================================================
#                     -- PRIVATE METHODS --
#========================================================================

sub _init {
    my ($self, $config) = @_;

    $self->{ SERVICE } = $config->{ SERVICE }
	|| Template::Config->service($config)
	|| return $self->error(Template::Config->error);

    $self->{ OUTPUT      } = $config->{ OUTPUT } || \*STDOUT;
    $self->{ OUTPUT_PATH } = $config->{ OUTPUT_PATH };

    return $self;
}



1;

__END__

=head1 NAME

Template - front-end module for the Template Toolkit

=head1 SYNOPSIS

    use Template;

    $tt = Template->new(\%config)
        || die Template->error(), "\n";

    $tt->process($template, \%vars)
        || die $tt->error(), "\n";

=head1 DESCRIPTION

The Template Toolkit is a collection of modules which implement a
fast, flexible and powerful template processing system.  The modules
that comprise the toolkit can be customised and interconnected in
different ways to create bespoke template processing engines for
different application areas or environments. 

The Template.pm module is a front-end to the Template Toolkit,
providing access to the full range of functionality through a single
module with a simple interface.  It loads the other modules as
required and instantiates a default set of objects to handle
subsequent template processing requests.  Configuration parameters may
be passed to the Template.pm constructor, new(), which are then used
to configure the individual objects.

Example:

    use Template;

    my $tt = Template->new({
	INCLUDE_PATH => '/usr/local/templates',
	EVAL_PERL    => 1,
    }) || die Template->error(), "\n";

    my $vars = {
	foo  => 'The Foo Value',
	bar  => 'The Bar Value',
    };

    $tt->process('welcome.html', $vars)
        || die $tt->error(), "\n";
    

=head1 METHODS

=head2 new(\%config)

The new() constructor method (implemented by the Template::Base base
class) instantiates a new Template object.  A reference to a hash
array of configuration items may be passed as a parameter.

    my $tt = Template->new({
	INCLUDE_PATH => '/usr/local/templates',
	EVAL_PERL    => 1,
    }) || die Template->error(), "\n";

A reference to a new Template object is returned, or undef on error.  In
the latter case, the error message can be retrieved by calling error()
as a class method (e.g. C<Template-E<gt>error()>) or by examing the $ERROR
package variable directly (e.g. C<$Template::ERROR>).

    my $tt = Template->new(\%config)
        || die Template->error(), "\n";

    my $tt = Template->new(\%config)
        || die $Template::ERROR, "\n";

For convenience, configuration items may also be specified as a list
of items instead of a hash array reference.  These are automatically
folded into a hash array by the constructor.

    my $tt = Template->new(INCLUDE_PATH => '/tmp', POST_CHOMP => 1)
	|| die Template->error(), "\n";


=head2 process($template, \%vars, $output)

The process() method is called to process a template.  The first
parameter indicates the template by filename (relative to
INCLUDE_PATH, if defined), or by reference to a text string containing
the template text, or to a file handle (e.g. IO::Handle or sub-class)
or GLOB (e.g. \*STDIN), from which the template can be read.

    $text = "[% INCLUDE header %]\nHello world!\n[% INCLUDE footer %]";

    $tt->process('welcome.tt2')
        || die $tt->error(), "\n";

    $tt->process(\$text)
        || die $tt->error(), "\n";

    $tt->process(\*DATA)
        || die $tt->error(), "\n";

    __END__
    [% INCLUDE header %]
    This is a template defined in the __END__ section which is 
    accessible via the DATA "file handle".
    [% INCLUDE footer %]

A reference to a hash array may be passed as the second parameter,
containing definitions of template variables.  This may contain values
of virtually any Perl type, including simple values, list and hash
references, sub-routines and objects.  The Template Toolkit will
automatically apply the correct procedure to accesing these values as
they are used in the template (e.g. index into a hash or array, call
code or object methods, provide virtual methods such as 'first', 'last',
etc.)

Example:

    my $vars = {
	foo => 'The Foo Value',
	bar => [ 2, 3, 5, 7, 11, 13 ],
	baz => { id => 314, name => 'Mr. Baz' },
	wiz => sub { return "You called the 'wiz' sub-routine!" },
	woz => MyObject->new(),
    };

    $tt->process('welcome.tt2', $vars)
        || die $tt->error(), "\n";

F<welcome.tt2>:

    [% foo %]
    [% bar.first %] - [% bar.last %], including [% bar.3 %]
    [% bar.size %] items: [% bar.join(', ') %]
    [% baz.id %]: [% baz.name %]
    [% wiz %]
    [% woz.method(123) %]

Output:

    The Foo Value
    2 - 13, including 7
    6 items: 2, 3, 5, 7, 11, 13
    314: Mr. Baz
    You called the 'wiz' sub-routine!
    # output of calling $vars->{'woz'}->method(123)

By default, the processed template output is printed to STDOUT.  The
process() method then returns 1 to indicate success.  A third
parameter may be passed to the process() method to specify a different
output location.  This value may be one of; a plain string indicating
a filename which will be opened (relative to OUTPUT_PATH, if defined)
and the output written to; a file GLOB opened ready for output; a
reference to a scalar (e.g. a text string) to which output/error is
appended; a reference to a sub-routine which is called, passing the
output as a parameter; or any object reference which implements a
'print' method (e.g. IO::Handle, Apache::Request, etc.) which will 
also be called, passing the generated output.

Examples:

    $tt->process('welcome.tt2', $vars, 'welcome.html')
        || die $tt->error(), "\n";

    $tt->process('welcome.tt2', $vars, 
		 sub { my $output = shift; print $output })
        || die $tt->error(), "\n";

    my $output = '';
    
    $tt->process('welcome.tt2', $vars, \$output)
        || die $tt->error(), "\n";
    
    print "output: $output\n";

In an Apache/mod_perl handler:

    sub handler {
	my $r    = shift;
	my $file = $r->path_info();

        my $tt   = Template->new();
	my $vars = { ... }

	# direct output to Apache::Request via $r->print($output)
	$tt->process($file, $vars, $r) || do {
	    $r->log_reason($tt->error());
	    return SERVER_ERROR;
	};

	return OK;
    }

The OUTPUT configuration item can be used to specify a default output 
location other than \*STDOUT.  The OUTPUT_PATH specifies a directory
which should be prefixed to all output locations specified as filenames.

    my $tt = Template->new({
	OUTPUT      => sub { ... },       # default
	OUTPUT_PATH => '/tmp',
	...
    }) || die Template->error(), "\n";

    # use default OUTPUT (sub is called)
    $tt->process('welcome.tt2', $vars)
        || die $tt->error(), "\n";

    # write file to '/tmp/welcome.html'
    $tt->process('welcome.tt2', $vars, 'welcome.html')
        || die $tt->error(), "\n";

The process() method returns 1 on success or undef on error.  The error
message generated in the latter case can be retrieved by calling the
error() method.  See also L<CONFIGURATION ITEMS> which describes how
error handling may be further customised.


=head2 error()

When called as a class method, it returns the value of the $ERROR package
variable.  Thus, the following are equivalent.

    my $tt = Template->new()
        || die Template->error(), "\n";

    my $tt = Template->new()
        || die $Template::ERROR, "\n";

When called as an object method, it returns the value of the internal
_ERROR variable, as set by an error condition in a previous call to
process().

    $tt->process('welcome.tt2')
        || die $tt->error(), "\n";


=head2 service()

The Template module delegates most of the effort of processing templates
to an underlying Template::Service object.  This method returns a reference
to that object.

=head2 context()

The Template::Service module uses a core Template::Context object for
runtime processing of templates.  This method returns a reference to 
that object and is equivalent to $template->service->context();

=head1 CONFIGURATION ITEMS

The Template module constructor, new(), accepts a hash array reference as
a parameter, or a list of keys and values which are folded into a hash 
array.  e.g.

    my $tt = Template->new({
	INCLUDE_PATH => '/home/abw/templates',
	POST_CHOMP   => 1,
    });

    my $tt = Template->new(
	INCLUDE_PATH => '/home/abw/templates',
	POST_CHOMP => 1
    );

This configuration hash is then passed to the other Template Toolkit
object constructors as they are called.  The following sections
described the configuration items used by each module.  See the
individual module documentation for further details.

=head2 Template

The Template module provides a front-end to the Template Toolkit.  It calls
on an underlying Template::Service object to process templates and then 
directs the returned output according to the OUTPUT and OUTPUT_PATH 
values, or any specific output location provided as the third parameter
to process().

=over 4

=item  OUTPUT

Default output location or handler.  May be overridden by specifying a
third parameter to process().

=item OUTPUT_PATH

The OUTPUT_PATH can be used to specify the output directory to which 
output files are written.

=item SERVICE

A reference to a Template::Service object, or sub-class thereof, to which
the Template module should delegate.  If unspecified, a Template::Service
object is automatically created using the current configuration hash.

=back

=head2 Template::Service

The Template::Service module implements a service object which
processes templates, adding headers and footers (PRE_PROCESS and
POST_PROCESS templates), and checking for errors.  These may be
handled automatically be specification of an ERROR hash array which
maps error types to template files.  Errors raised in a template will
then be handled by processing the appropriate template.

=over 4

=item PRE_PROCESS, POST_PROCESS

One or more templates to be processed before and/or after the main 
template.  Multiple templates may be delimited by any sequence of
non-word characters, or specified as a list reference,

    my $tt = Template->new({
	PRE_PROCESS  => 'config, header',  # or ['config', 'header']
        POST_PROCESS => 'footer',
    });

=item ERROR

Hash array of error handling templates.  If an exception is thrown in
the main process template that has a relevant handler defined in the
ERROR hash (i.e. the hash key matches the error type), then the
template named as the relevant hash value will be processed in place
of the original template.  A 'default' template may be provided to
handle any otherwise uncaught error types.  

Any PRE_PROCESS and/or POST_PROCESS templates will be added to the
ERROR template.  The 'error' template variable is set to reference the
Template::Exception object representing the error.  Errors raised in
PRE_PROCESS or POST_PROCESS templates, or in the ERROR templates
themselves will be returned immediately without any further error
handling.

    my $tt = Template->new({
	PRE_PROCESS  => 'config, header',
        POST_PROCESS => 'footer',
	ERROR => {
	    dbi     => 'errors/database.tt2',
	    default => 'error.tt2',
	},
    });

=item BLOCKS

A hash array of pre-defined template blocks that may be subsequently
used via the INCLUDE directive.  The values should contain instances
of Template::Document objects or code references which take a reference
to a Template::Context as a parameter and return the output generated.

    my $tt = Template->new({
	PRE_PROCESS  => 'config',
        POST_PROCESS => 'footer',
	BLOCKS       => {
	    'header' => sub { my $context = shift; return "HEADER!" },
	    'footer' => Template::Document->new(...),
	},
    });

=item CONTEXT

A reference to a Template::Context object, or sub-class thereof, which
manages runtime processing of templates and implements the main
directive features.  If undefined, a Template::Context object is
automatically created using the current configuration hash.

=back    

=head2 Template::Context

=over 4

=item TEMPLATES

A list of Template::Provider or derived objects which implement a
chain of command for loading, compiling and caching templates.  If
undefined, a default Template::Provider object is created as the sole
TEMPLATES item using the current configuration hash.

=item PLUGINS

Ditto for loading plugins.  A default Template::Plugins object is created
if undefined.

=item FILTERS

Ditto for loading filters.  A default Template::Filters object is created
if undefined.

=item VARIABLES, PRE_DEFINE

May be used to specify a set of variables which should be pre-defined
each time the service is run (i.e. process() is called).  These are
passed to the Template::Stash constructor but are ignore if the STASH
item is defined (see below).  The names 'VARIABLES' and 'PRE_DEFINE'
are synonymous and either can be used to equal effect.

=item STASH 

A reference to a Template::Stash object, or sub-class thereof, which
manages template variables.

=back

=head2 Template::Provider

The Template::Provider module is used for loading, compiling and
caching template documents.  The Template.pm new() constructor creates
a Template::Provider object unless the PROVIDERS option is set (see below).
The following options are applicable:

=over 4

=item INCLUDE_PATH

A string containing one or more directories, delimited by ':', from
which templates should be loaded.  Alternatively, a list reference
of directories may be provided.

=item ABSOLUTE

Flag used to indicate if files specified by absolute filename (e.g. 
'/foo/bar') should be loaded.

=item RELATIVE

Flag used to indicate if files specified by relative filename (e.g. 
'./foo/bar') should be loaded.

=item SIZE

The maximum number of compiled templates that the object should cache.
A zero value indicates that no caching should be performed.  If undefined
then all templates will be cached.

=item TOLERANT

If the TOLERANT flag is set then all errors will downgraded to declines.

=item DELIMITER

Alternative character(s) for delimiting INCLUDE_PATH (default ':').
May be useful for operating systems that use ':' in file names.

=item PARSER

Used to provide a reference to a Template::Parser object, or derivative,
which should be used to compile template documents as they are loaded.
A default Template::Parser object is created if unspecified.

=back

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision$

=head1 COPYRIGHT

Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>

=cut




if PROVIDERS 
   foreach p in PROVIDERS 
