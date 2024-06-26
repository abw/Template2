# Quick Install

If you have the CPAN module installed then you can install the Template
Toolkit like this from the command line:

    $ cpan Template

Otherwise you can install from source code. The latest version of the Template
Toolkit can be retrieved from:

    http://www.cpan.org/modules/by-module/Template/

Fetch and install AppConfig 1.56 if you don't already have it installed.
Available from CPAN in:

    http://www.cpan.org/authors/Andy_Wardley/

To install the Template Toolkit from the command line:

    $ tar zxf Template-Toolkit-3.102.tar.gz
    $ cd Template-Toolkit-3.102
    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

The Makefile.PL will prompt for any additional configuration options.

For further details, see the sections below on CONFIGURATION, BUILDING
AND TESTING, and INSTALLATION.  The Template Toolkit web site also has
further information about installation.

    http://template-toolkit.org/download/index.html

# Prerequisites

The Template Toolkit is written entirely in Perl and should run on any
platform on which Perl is available.  It requires Perl 5.006 or later.

The 'ttree' utility uses the AppConfig module (version 1.56 or above)
for parsing command line options and configuration files.  It is
available from CPAN:

    http://www.cpan.org/authors/Andy_Wardley/

The Template Toolkit implements a "plugin" architecture which allow
you to incorporate the functionality of virtually any Perl module into
your templates.  A number of plugin modules are included with the
distribution for adding extra functionality or interfacing to external
CPAN modules.  You don't need to install any of these external modules
unless you plan to use those particular plugins.  See Template::Plugins
and Template::Manual::Plugins for further details.


# Obtaining and Installing the Template Toolkit

The latest release version of the Template Toolkit can be downloaded
from any CPAN site:

    http://www.cpan.org/modules/by-module/Template/

Interim and development versions may also be available, along with
other useful information, news, publications, mailing list archives,
etc., from the Template Toolkit web site:

    http://template-toolkit.org/

The Template Toolkit is distributed as a gzipped tar archive file:

    Template-Toolkit-<version>.tar.gz

where `version` represents the current version number, e.g. 3.100.

To install the Template Toolkit, unpack the distribution archive to
create an installation directory.  Something like this:

    $ tar zxf Template-Toolkit-3.102.tar.gz
or
    $ gunzip Template-Toolkit-3.102.tar.gz
    $ tar xf Template-Toolkit-3.102.tar

You can then 'cd' into the directory created,

    $ cd Template-Toolkit-3.102

and perform the usual Perl installation procedure:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install	    # may need root access

The Makefile.PL performs various sanity checks and then prompts for a
number of configuration items.  The following CONFIGURATION section
covers this in greater detail.

If you choose to install the optional components then you may need to
perform some post-installation steps to ensure that the template
libraries, HTML documentation and examples can be correctly viewed via
your web browser.  The INSTALLATION section covers this.


# Installing on Microsoft WIN32 Platforms

For advice on using Perl under Microsoft Windows, have a look here:

    http://win32.perl.org/

If you're using Strawberry Perl then you can install the Template
Toolkit using the CPAN module as described above.

If you're using ActivePerl then you can install it using the Perl Package
Manager (ppm) with the pre-compiled packages built by Chris Winters. For
further details, see:

    http://openinteract.sourceforge.net/
    http://activestate.com/

If you prefer, you can manually install the Template Toolkit on Win32
systems by following the instructions in this installation guide.
However, please note that you are likely to encounter problems using
'make' and should instead download and use 'nmake' as a replacement.
This is available from Microsoft's ftp site.

    ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe

In this case, you should substitute 'nmake' for 'make' in all the
instructions contained herein.


# Configuration

This section covers the configuration of the Template Toolkit via
the Makefile.PL program.  If you've successfully run this and didn't
have any problems answering any of the questions then you probably
don't need to read this section.

The Makefile.PL Perl program performs the module configuration and
generates the Makefile which can then be used to build, test and
install the Template Toolkit.

    $ perl Makefile.PL

The Template Toolkit now boasts a high-speed implementation of
Template::Stash written in XS.  You can choose to build this as
an optional module for using explicitly as an alternative to
the regular pure-perl stash module.  In additional, you can opt
to use the XS Stash as the default, typically making the Template
Toolkit run twice as fast!

When prompted, answer 'y' or 'n' to build and optionally use
the XS Stash module by default:

    Do you want to build the XS Stash module? [y]
    Do you want to use the XS Stash for all Templates? [n]

# Building and Testing

This section describes the "make" and "make test" commands which build
and test the Template Toolkit.  If you ran these without incident,
then you can probably skip this section.

The 'make' command will build the Template Toolkit modules in the
usual manner.

    make

The 'make test' command runs the test scripts in the 't' subdirectory.

    make test

You can set the TEST_VERBOSE flag when running 'make test' to see the
results of the individual tests:

    make test TEST_VERBOSE=1


# Installation

This section describes the final installation of the Template Toolkit
via the "make install" and covers any additional steps you may need to
take if you opted to build the HTML documentation and/or examples.

The 'make install' will install the modules and scripts on your
system.  You may need administrator privileges to perform this task.
Alternately you can can install the Template Toolkit to a local
directory (see ExtUtils::MakeMaker for full details), e.g.

    $ perl Makefile.PL PREFIX=/home/abw/

Don't forget to update your PERL5LIB environment variable if you do
this, or add a line to your script to tell Perl where to find the files,
e.g.

    use lib qw( /home/abw/lib/perl5/site_perl/5.10.0 );

