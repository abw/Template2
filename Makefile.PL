#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use lib qw( ./lib );
use Config;
use File::Spec::Functions qw( catfile );
use Template;
use ExtUtils::MakeMaker;
use Cwd;

select STDERR;
$| = 1;
select STDOUT;

use vars qw( $TT_VERSION $TT_PREFIX $TT_IMAGES 
             $TT_BUILD_DOCS $TT_SPLASH_DOCS $TT_EXAMPLES $TT_EXTRAS
             $TT_XS_ENABLE $TT_XS_DEFAULT
             $TT_SPLASH_THEME $TT_QUIET $TT_ACCEPT $TT_YES );

# check O/S to set sensible defaults

my ($WIN32, $FLAVOUR, $PREFIX, $IMAGES, $MAKE);
if ($^O eq 'MSWin32') {  # any others also?
    $WIN32   = 1;
    $FLAVOUR = 'Win32';
    $PREFIX  = 'C:/Program Files/Template Toolkit 2';
    $IMAGES  = '/tt2/images';
    $MAKE    = 'nmake';
}
else {
    $WIN32   = 0;
    $FLAVOUR = 'Unix';
    $PREFIX  = '/usr/local/tt2';
    $IMAGES  = '/tt2/images';
    $MAKE    = 'make';
}


# read command line args putting TT_* into $ttconfig and
# everything else (regular Makefile.PL args, e.g. PREFIX)
# goes into $config

my (%config, %ttconfig);
while ($_ = shift) {
    my ($k, $v) = split(/=/);
    if ($k =~ /^TT/) {
        $ttconfig{ $k } = $v || 0;
    }
    else {
        $config{ $k } = $v || 0;
    }
};


# print help if they asked for it

if (exists $ttconfig{ TT_HELP }) {
    print <<EOF;
The following options can be specified as command line 
arguments to 'perl Makefile.PL'.  e.g.

  perl Makefile.PL TT_PREFIX=/my/tt2/dir TT_ACCEPT=y

  TT_PREFIX      installation prefix     ($PREFIX)
  TT_IMAGES      images URL              (/tt2/images)
  TT_DOCS        build HTML docs         (y)
  TT_SPLASH      use Splash! for docs    (y)
  TT_THEME       Splash! theme           (default)
  TT_EXAMPLES    build HTML examples     (y)
  TT_EXTRAS      install optional extras (y)
  TT_XS_ENABLE   Enable XS Stash         (y)
  TT_XS_DEFAULT  Use XS Stash by default (y)
  TT_QUIET       no messages	         (n)
  TT_ACCEPT      accept defaults         (n)

By default, the Makefile.PL runs in interactive mode, 
prompting for confirmation of the various configuration
options.  Setting the TT_ACCEPT option causes the default
value (possibly modified by other command line options)
to be accepted.  The TT_QUIET option can also be set to
suppress the prompt messages.

EOF
    exit(0);
}

# these global package variables are the main flags used
# in this script, here defaulted to sensible values

$TT_VERSION       = $Template::VERSION;
$TT_PREFIX        = $PREFIX;
$TT_IMAGES        = $IMAGES;
$TT_BUILD_DOCS    = 'y';
$TT_SPLASH_DOCS   = 'y';
$TT_EXAMPLES      = 'y';
$TT_EXTRAS        = 'y';
$TT_SPLASH_THEME  = 'default';
$TT_XS_ENABLE     = 'y';
$TT_XS_DEFAULT    = 'y';
$TT_QUIET         = 'n';
$TT_ACCEPT        = 'n';

my $TT_SPLASH_FG  = '';
my $TT_SPLASH_BG  = '';
my $TT_SPLASH_FT  = '';
my $TT_SPLASH_BT  = '';

my $DEFAULTS_FILE   = '.defaults.cfg';
my $TT_DOCS_CFG     = catfile('docs','ttree.cfg');
my $TT_EXAMPLE_CFG  = catfile('examples','ttree.cfg');
my $DEFAULTS = '';

if (-f $DEFAULTS_FILE) {
    require $DEFAULTS_FILE;
    $DEFAULTS = " read from '$DEFAULTS_FILE'";
}

$TT_PREFIX        = $ttconfig{ TT_PREFIX     } if $ttconfig{ TT_PREFIX     };
$TT_IMAGES        = $ttconfig{ TT_IMAGES     } if $ttconfig{ TT_IMAGES     };
$TT_SPLASH_THEME  = $ttconfig{ TT_THEME      } if $ttconfig{ TT_THEME      };
$TT_BUILD_DOCS    = $ttconfig{ TT_DOCS       } if defined $ttconfig{ TT_DOCS       };
$TT_SPLASH_DOCS   = $ttconfig{ TT_SPLASH     } if defined $ttconfig{ TT_SPLASH     };
$TT_EXAMPLES      = $ttconfig{ TT_EXAMPLES   } if defined $ttconfig{ TT_EXAMPLES   };
$TT_EXTRAS        = $ttconfig{ TT_EXTRAS     } if defined $ttconfig{ TT_EXTRAS     };
$TT_XS_ENABLE     = $ttconfig{ TT_XS_ENABLE  } if defined $ttconfig{ TT_XS_ENABLE  };
$TT_XS_DEFAULT    = $ttconfig{ TT_XS_DEFAULT } if defined $ttconfig{ TT_XS_DEFAULT };
$TT_QUIET         = $ttconfig{ TT_QUIET      } if defined $ttconfig{ TT_QUIET      };

if (defined $ttconfig{ TT_ACCEPT }) {
    $TT_ACCEPT = $ttconfig{ TT_ACCEPT };
}
else {
    # standard behaviour for MakeMaker to indicate accept all defaults
    $TT_ACCEPT = $ENV{PERL_MM_USE_DEFAULT} ? 'y' : 'n';
}

foreach ($TT_BUILD_DOCS, $TT_SPLASH_DOCS, $TT_EXAMPLES, 
	 $TT_EXTRAS, $TT_XS_ENABLE, $TT_XS_DEFAULT ) {
    $_ = 'n' if ! $_;
}
$TT_ACCEPT = 0 if $TT_ACCEPT eq 'n';
$TT_QUIET  = 0 if $TT_QUIET eq 'n';
$TT_QUIET  = 0 unless $TT_ACCEPT;

my $SPLASH_STYLES = {
    default => [ 'lilac',  'mauve'   ],
    aqua    => [ 'aqua',   'marine'  ],
    grey    => [ 'grey75', 'grey50'  ],
    blue    => [ 'grey75', 'blue75'  ],
    red     => [ 'grey75', 'red75'   ],
    green   => [ 'grey75', 'green75' ],
    leon    => [ 'red75',  'orange', 'white', 'black' ],
};


# define version numbers of required modules
my $TT_APPCONFIG_VERSION = '1.56';
my $TT_FILE_SPEC_VERSION = '0.8';
my $TT_FILE_TEMP_VERSION = '0.12';


#========================================================================

welcome_message();
version_check();
mandatory_modules();
optional_stash_xs();
optional_extras();
splash_images();
html_docs();
html_docstyle();
html_examples();
write_defaults();

print "\n";


#------------------------------------------------------------------------ 
# build options and write Makefile
#------------------------------------------------------------------------

package MY;

sub postamble {
    return '' unless $main::TT_PREFIX;
    my $amble =<<'EOF';
tt2_install ::
	@$(PERL) bin/tt2inst -v "$(TT_PREFIX)"

tt2_splash ::
	@$(PERL) -I$(INST_LIB) -I$(INST_ARCHLIB) bin/gifsplash -v -i "$(TT_PREFIX)"

EOF
    $amble .=<<EOF if $main::TT_BUILD_DOCS;
tt2_html_docs ::
	\@\$(PERL) -I\$(INST_LIB) -I\$(INST_ARCHLIB) bin/ttree -v -f "\$(TT_PREFIX)/$TT_DOCS_CFG"

EOF
    $amble .=<<EOF if $main::TT_EXAMPLES;
tt2_examples ::
	\@\$(PERL) -I\$(INST_LIB) -I\$(INST_ARCHLIB) bin/ttree -v -f "\$(TT_PREFIX)/$TT_EXAMPLE_CFG"

EOF
    return $amble;
}

sub install {
    my $class = shift;
    my $basic = $class->SUPER::install(@_);
    my $add   = 'tt2_install tt2_splash';
    $add .= ' tt2_html_docs' if $main::TT_BUILD_DOCS;
    $add .= ' tt2_examples' if $main::TT_EXAMPLES;
    $basic =~ s/^(install\s+::\s+.*)$/$1 $add/m
	if $main::TT_PREFIX;
    $basic;
}

sub constants {
    my $class = shift;
    my $basic = $class->SUPER::constants(@_);
    $basic = "TT_PREFIX = $main::TT_PREFIX\n$basic"
	if $main::TT_PREFIX;
    $basic;
}

package main;
    
my %opts = (
    %config,
    'NAME'	       => 'Template',
    'DISTNAME'     => 'Template-Toolkit',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage', 'bin/ttree' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'DIR'          => [ ],
    'PREREQ_PM'    => { 
        'AppConfig'    => $TT_APPCONFIG_VERSION,
        'File::Spec'   => $TT_FILE_SPEC_VERSION,
        'File::Temp'   => $TT_FILE_TEMP_VERSION,
    },
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
    'clean'        => {
        'FILES'        => join(' ', qw( docs/ttree.cfg 
                                        examples/ttree.cfg 
                                        t/dbi_test.cfg 
                                        t/test/src/baz.ttc
                                        t/test/src/complex.org 
                                        t/test/src/complex.ttc
                                        t/test/src/evalperl.ttc
                                        t/test/src/foo.ttc )),
    },
);

push @{ $opts{'DIR'} }, 'xs' if $TT_XS_ENABLE;

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>';
    $opts{ ABSTRACT } = 'comprehensive template processing system',
}


WriteMakefile( %opts );

    print <<EOF;

Configuration complete.  You should now run '$MAKE', '$MAKE test' and 
then '$MAKE install'.   See the README file for further information.
EOF

message(<<EOF) if $TT_PREFIX;


Installation Notes
------------------

Please note that the installation of the optional components and
building of the HTML documentation is performed at the "make install"
stage as the effective user at that time.  This implies that this user
must have sufficient permission to install into the specified
directory and that all created directories and files will be owned by
them.

EOF

#========================================================================



#------------------------------------------------------------------------
# welcome_message()
#
# Print opening banner.
#------------------------------------------------------------------------

sub welcome_message {
    print(<<EOF);

                    Template Toolkit Version $TT_VERSION
                    =============================

Using $FLAVOUR defaults$DEFAULTS.
Run 'perl Makefile.PL TT_HELP' for a summary of options.
EOF
    print "Messages suppressed (TT_QUIET).  " if $TT_QUIET;
    print "Accepting defaults automatically (TT_ACCEPT)." if $TT_ACCEPT;
}



#------------------------------------------------------------------------
# version_check()
#
# Check for pre-version 2.00 installation and issue warning
#------------------------------------------------------------------------

sub version_check {
    eval "use Template";
    unless ($@ or $Template::VERSION =~ /^2/) {
	warn(<<EOF) unless $TT_QUIET;

IMPORTANT NOTE:

    You have version $Template::VERSION of the Template Toolkit installed.

    There are some minor incompatabilities between version 1 and 2
    of the Template Toolkit which you should be aware of.  Installing
    this version will overwrite your version $Template::VERSION files
    unless you take measures to install one or the other version in a
    different location (i.e. perl Makefile.PL PREFIX=/other/path).  

    Please consult the README and Changes file for further details.
    Most of the changes are in the more obscure features and
    directives so hopefully you will find the upgrade process fairly
    painless.  If you're feeling brave, then answer 'y', otherwise 'n'.

EOF
	exit unless ttprompt("Do you want to continue?", 'y') =~ /y/i;
    }
}


#------------------------------------------------------------------------
# mandatory_modules()
#
# Detect mandatory module
#------------------------------------------------------------------------

sub mandatory_modules {
    eval "use AppConfig";
    if ($@ or $AppConfig::VERSION < $TT_APPCONFIG_VERSION) {
	warn(<<EOF);

The Template Toolkit requires that the AppConfig module (version $TT_APPCONFIG_VERSION
or later) first be installed.  This is used by
the 'ttree' program for reading command line options and configuration
files.  It is available from CPAN:

    http://www.cpan.org/authors/Andy_Wardley/

EOF
    }

    eval "use File::Spec";
    if ($@ or $File::Spec::VERSION < $TT_FILE_SPEC_VERSION) {
	warn(<<EOF);

The Template Toolkit requires that the File::Spec module (version $TT_FILE_SPEC_VERSION
or later) first be installed.  This is used by the File plugin.  It is
available from CPAN:

    http://search.cpan.org/search?dist=File-Spec

EOF
    }

    eval "use File::Temp";
    if ($@ or $File::Temp::VERSION < $TT_FILE_TEMP_VERSION) {
        warn(<<EOF);

The Template Toolkit requires that the File::Temp module (version $TT_FILE_TEMP_VERSION
or later) first be installed.  This is used by the Template::Document
class for storing compiled templates.  It is available from CPAN:

    http://search.cpan.org/search?dist=File-Temp

EOF
    }
}


#------------------------------------------------------------------------
# optional_stash_xs()
#
# Prompt for installation and default use of XS Stash.
#------------------------------------------------------------------------

sub optional_stash_xs {
#    return if $TT_ACCEPT && (! $TT_XS_ENABLE || $TT_XS_ENABLE eq 'n');

    message(<<EOF);


Template::Stash::XS
-------------------

The Template::Stash module is a core part of the Template Toolkit, 
implementing the magic for accessing data using the dot notation.

There is a high speed version, Template::Stash::XS, written in C.
This makes the Template Toolkit run about twice as fast as when using
the regular Template::Stash written in Perl.  If you've got a C
compiler on your system then you can elect to have the XS Stash built.
You can also specify that you want to use the XS Stash by default.

Note that as of version 2.15 the XS Stash now supports access to tied
hashes and arrays.

See 'perldoc Template::Config' for further details.

EOF

    $TT_XS_ENABLE = (ttprompt('Do you want to build the XS Stash module?', 
			      $TT_XS_ENABLE) =~ /^y/i);

    if ($TT_XS_ENABLE) {
        $TT_XS_DEFAULT =
            (ttprompt('Do you want to use the XS Stash by default?', 
                      $TT_XS_DEFAULT) =~ /^y/i); 
    }
    else {
        # If the XS stash is disabled, we cannot use it as the default stash.
        $TT_XS_DEFAULT = 0;
    }

    # Actually, we would have to fix 'Config.pm' only if the XS stash is
    # disabled. But this way, we are sure the correct module is used.
	fix_file(catfile('lib','Template','Config.pm'),
		 '$STASH', 
		 $TT_XS_DEFAULT ? 'Template::Stash::XS' : 'Template::Stash');
}




#------------------------------------------------------------------------
# optional_extras()
#
# Prompt for installation of optional libraries and other components
#------------------------------------------------------------------------

sub optional_extras {
    message(<<EOF);


Optional Extras
---------------

In additional to the Perl modules and POD documentation installed in
the usual way, the Template Toolkit distribution also contains a
number of optional components:

  * Template libaries for basic HTML, Pod -> HTML, and PostScript

  * Splash! - a stylish HTML user interface template library / widget set

  * HTML documentation - distributed in template form for customisation

  * Stylesheet templates to generate docs as vanilla HTML or using Splash!

  * Examples - numerous examples of using the template libraries

If you want to install these optional components then you'll need to 
specify a separate directory for them.

EOF

    if ($TT_EXTRAS = (
        ttprompt('Do you want to install these components?',
            $TT_EXTRAS) =~ /^y/i)) {
	message(<<EOF);

You can chose any directory for the installation of the additional
Template Toolkit components.  The proposed default assumes a $FLAVOUR
flavour to your operating system (suggestions for suitable defaults
for other platforms welcome).

EOF
	$TT_PREFIX = ttprompt('Installation directory', $TT_PREFIX || $PREFIX);
        $TT_PREFIX =~ s[/$][];
    }
    else {
        $TT_PREFIX = '';
    }

    fix_file(catfile('lib','Template','Config.pm'), '$INSTDIR', $TT_PREFIX);
}



#------------------------------------------------------------------------
# splash_images()
#
# Prompt for Splash! image URL
#------------------------------------------------------------------------

sub splash_images {
    return unless $TT_PREFIX;

    message(<<EOF);


Splash!
-------

The Splash! template library uses a number of (very) small images to
build user interface components.  These will be installed into the
directory:

    $TT_PREFIX/images  
EOF

    if ($WIN32) {
	# default images value for Win32 to browse via file system
	$TT_IMAGES = "$TT_PREFIX/images";
	
	message(<<EOF);
	
If you want to use the Splash! library then you'll need to make sure
you can access these images via your browser.  If you want to deliver
pages via a web server then you'll need to specify the URL that can be
use to access these images.  In the general case you can accept the
default and access the images via the filesystem.

EOF
    }
    else {
        message(<<EOF);

If you want to use the Splash! library then you'll need to copy these
images, define an alias (e.g. in the httpd.conf) or create a symbolic
link to them so that your web server can find them.  Then you'll need
to specify the resulting URL which can be used to retrieve them from
the web server.

Typical values might be '/tt2/images', '/images/tt2', '/~user/tt2/images'
or even something like 'http://www.yourhost.org/images/tt2'.

(NOTE: If this is too much for you to think about right now, then
accept the default below and read the Template::Library::Splash
manpage at your leisure to find out more).

EOF
    }

    $TT_IMAGES = ttprompt('URL base for TT2 images?', $TT_IMAGES || $IMAGES);
    $TT_IMAGES =~ s[/$][]g;	# just in case

    fix_file(catfile('templates','splash','config'), 'images', "$TT_IMAGES/splash");
}



#------------------------------------------------------------------------
# html_docs()
#
# Prompt for HTML documentation build
#--------------------------------------------------------------------

sub html_docs {
    return unless $TT_PREFIX;

    my $style = 'plain';
    my $style_cfg = '';

    message(<<EOF);


HTML Documentation
------------------

The modules comprising the Template Toolkit contain comprehensive POD
documentation which can be browsed using 'perldoc' or 'man' (if your
system supports it).  In additional, the distribution also includes a
set of source templates and style elements for generating the same
documentation in HTML format.  These will be installed in the
directory:

    $TT_PREFIX/docs

The HTML documentation can be built for you at "make install" time in
a plain and simple HTML format or using the Splash! library.  You can
see examples of these different styles and browse the documentation
online at:

    http://www.template-toolkit.org/docs/

EOF

    $TT_BUILD_DOCS = ( 
    	ttprompt('Do you want to build the HTML documentation?', 
                 $TT_BUILD_DOCS) =~ /^y/i 
    );

}


#--------------------------------------------------------------------
# html_docstyle()
#
# prompt for docs style: plain or splash
#--------------------------------------------------------------------

sub html_docstyle {
    return unless $TT_PREFIX && $TT_BUILD_DOCS;

    my $style = 'plain';
    my $style_cfg = '';

    message(<<EOF);

If you want to build the HTML documentation using the Splash! library
then you'll need to make sure you correctly defined the URL for the
Splash!  images above.  Otherwise, answer 'n' to the next question to
use plain HTML.

EOF
    $TT_SPLASH_DOCS = ( 
    	ttprompt('Do you want to use the Splash! library?', $TT_SPLASH_DOCS) =~ /^y/i 
    );

    if ($TT_SPLASH_DOCS) {
        my $splash_style = '';
        message(<<EOF);

Which Splash! colour scheme would you like to use to build the
documentation?  Acceptable values are:

EOF
        unless ($TT_QUIET) {
            print "  Name     Colours\n  -------------------------\n";
    	    foreach my $t ('default', 
        		    grep { ! /^default$/ } sort keys %$SPLASH_STYLES) {
                my $v = $SPLASH_STYLES->{ $t };
                local $" = '/';
                printf("  %-8s @$v\n", $t);
            } 
            print "\n";
	
    	    while (! $splash_style) {
                $TT_SPLASH_THEME = ttprompt("Enter name of colour scheme: ", 
                                            $TT_SPLASH_THEME);
                message("! No such scheme\n"), $TT_SPLASH_THEME = 'default'
                    unless ($splash_style = $SPLASH_STYLES->{ $TT_SPLASH_THEME });
            }

            ( $TT_SPLASH_BG, $TT_SPLASH_FG, $TT_SPLASH_BT, $TT_SPLASH_FT ) 
                = @$splash_style;

    	    # default background (unselected) text is black, fore is white
            $TT_SPLASH_BT ||= 'black';
            $TT_SPLASH_FT ||= 'white';

    	    $style = 'splash';
            $style_cfg = <<EOF;

pre_process  = splash/config
define splash_fg = '$TT_SPLASH_FG'
define splash_bg = '$TT_SPLASH_BG'
define splash_ft = '$TT_SPLASH_FT'
define splash_bt = '$TT_SPLASH_BT'
EOF
        }
    }

    #--------------------------------------------------------------------
    # write ttree config file for building docs
    #--------------------------------------------------------------------

    open(FP, "> $TT_DOCS_CFG") || die "$TT_DOCS_CFG: $!\n";
    print FP <<EOF;
# This ttree configuration file is automatically generated by 
# the Makefile.PL installation script.  Feel free to edit it
# but be warned that re-installing the Template Toolkit will 
# overwrite your changes.
src  = $TT_PREFIX/docs/src
dest = $TT_PREFIX/docs/html
lib  = $TT_PREFIX/docs/style/$style
lib  = $TT_PREFIX/docs/lib
lib  = $TT_PREFIX/templates
$style_cfg
pre_process  = config
pre_process  = header
post_process = footer
recurse
verbose
EOF
    close(FP);
}




#--------------------------------------------------------------------
# html_examples()
#
# Prompt for building examples
#--------------------------------------------------------------------

sub html_examples {
    return unless $TT_PREFIX;

    message(<<EOF);


HTML Examples
-------------

A number of examples showing use of the HTML, Splash! and PostScript 
libraries will be installed into:

    $TT_PREFIX/examples

As with the documentation, the examples are provided in template form
and can be automatically built into HTML pages during the "make
install".  These pages rely on the Splash! library and expect the
images URL to be correctly defined for correct viewing.

EOF

    $TT_EXAMPLES = ( 
	ttprompt('Do you want to build the HTML example pages?', 
	       $TT_EXAMPLES) =~ /^y/i 
    );

    #--------------------------------------------------------------------
    # write ttree config file for building examples
    #--------------------------------------------------------------------

    open(FP, "> $TT_EXAMPLE_CFG") || die "$TT_EXAMPLE_CFG: $!\n";
    print FP <<EOF;
# This ttree configuration file is automatically generated by 
# the Makefile.PL installation script.  Feel free to edit it
# but be warned that re-installing the Template Toolkit will 
# overwrite your changes.

src  = $TT_PREFIX/examples/src
dest = $TT_PREFIX/examples/html
lib  = $TT_PREFIX/examples/lib
lib  = $TT_PREFIX/templates
define splash_fg = '$TT_SPLASH_FG'
define splash_bg = '$TT_SPLASH_BG'
pre_process = config
recurse
verbose
EOF

    close(FP);
}


#--------------------------------------------------------------------
# write_defaults()
#
# write configuration defaults to file
#--------------------------------------------------------------------

sub write_defaults {
    open(FP, "> $DEFAULTS_FILE") || die "$DEFAULTS_FILE: $!\n";
    my ( $ttdocs, $ttsplash, $ttexamples, 
         $ttextras, $ttxs_enable, $ttxs_default ) 
	    = map { $_ ? 'y' : 'n' } 
    ( $TT_BUILD_DOCS, $TT_SPLASH_DOCS, $TT_EXAMPLES, 
      $TT_EXTRAS, $TT_XS_ENABLE, $TT_XS_DEFAULT );
    print FP <<EOF;
\$TT_PREFIX        = '$TT_PREFIX';
\$TT_IMAGES        = '$TT_IMAGES';
\$TT_BUILD_DOCS    = '$ttdocs';
\$TT_SPLASH_DOCS   = '$ttsplash';
\$TT_EXAMPLES      = '$ttexamples';
\$TT_EXTRAS        = '$ttextras';
\$TT_SPLASH_THEME  = '$TT_SPLASH_THEME';
\$TT_XS_ENABLE     = '$ttxs_enable';
\$TT_XS_DEFAULT    = '$ttxs_default';
\$TT_ACCEPT        = '$TT_ACCEPT';
\$TT_QUIET         = '$TT_QUIET';
1;
EOF
    close(FP);
}


#------------------------------------------------------------------------
# build_docs()
#
# Echo the relevant incantation so that 'make dist' regenerates the 
# documentation from the template sources.
#------------------------------------------------------------------------

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)" ;           \\
\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) bin/ttree -f ./docs/ttdist.cfg --define version=\$(VERSION) -a;  \\
EOF
}



#------------------------------------------------------------------------
# fix_file($file, $find, $fix)
#
# Fixes a variable definition in a file.  e.g. 
# fix_file('templates/splash/config', 'images', '/tt2/splash')
#------------------------------------------------------------------------

sub fix_file {
    my ($file, $find, $fix) = @_;
    local *FP;
    local $/ = undef;

    $find = quotemeta($find);

    open(FP, "< $file") || die "$file: $!\n";
    my $text = <FP>;
    close(FP);

    ($text =~ s/^(\s*${find}\s*=\s*)'.*?'/$1'$fix'/m)
	|| die "$find not found in $file\n";

    open(FP, "> $file") || die "$file: $!\n";
    print FP $text;
    close(FP);
}


#------------------------------------------------------------------------
# find_program($path, $prog)
#
# Find a program, $prog, by traversing the given directory path, $path.
# Returns full path if the program is found.
#
# Written by Craig Barratt, Richard Tietjen add fixes for Win32.
#
# abw changed name from studly caps findProgram() to find_program() :-)
#------------------------------------------------------------------------

sub find_program {
    my($path, $prog) = @_;
#     my $sep = $WIN32 ? qr/;/ : qr/:/;
#     foreach my $dir ( split($sep, $path) ) {
    foreach my $dir ( split($Config{path_sep}, $path) ) {
        my $file = File::Spec->catfile($dir, $prog);
        if ( !$WIN32 ) {
            return $file if ( -x $file );
        } else {
            # Windows executables end in .xxx, exe precedes .bat and .cmd
            foreach my $dx ( qw/exe bat cmd/ ) {
                return "$file.$dx" if ( -x "$file.$dx" );
            }
        }
    }
}


#------------------------------------------------------------------------
# message($text)
#
# Print message unless quiet mode.
#------------------------------------------------------------------------

sub message {
    return if $TT_QUIET;
    print @_;
}


#------------------------------------------------------------------------
# ttprompt($message, $default)
#------------------------------------------------------------------------

sub ttprompt {
    my ($msg, $def)=@_;
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ; # Pipe?
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans = '';
    local $|=1;
    print "$msg $dispdef" unless $TT_QUIET;
    if ($TT_ACCEPT || ! $ISA_TTY) {
        print "$def\n" unless $TT_QUIET;
    }
    else {
        chomp($ans = <STDIN>);
    }
    return ($ans ne '') ? $ans : $def;
}


#------------------------------------------------------------------------
# yep($text)
#------------------------------------------------------------------------

sub yep {
    return if $TT_QUIET;
    print '[X] ', shift, "\n";
}


#------------------------------------------------------------------------
# nope($text)
#------------------------------------------------------------------------
sub nope {
    return if $TT_QUIET;
    print '[ ] ', shift, "\n";
}
