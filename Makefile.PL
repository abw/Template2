use ExtUtils::MakeMaker;				    # -*-perl-*-
use Cwd;

select STDERR;
$| = 1;
select STDOUT;

my $DBI_CONFIG_FILE = 't/dbi_test.cfg';
my $TT_INST_ROOT    = '/usr/local/tt2';   # should be more platform general
my $TT_IMAGES       = '/tt2/images';      # and honour existing installation
my $TT_BUILD_DOCS   = 'y';
my $TT_SPLASH_DOCS  = 'y';
my $TT_EXAMPLES     = 'y';
my $TT_DOCS_CFG     = 'docs/ttree.cfg';
my $TT_EXAMPLE_CFG  = 'examples/ttree.cfg';

print <<EOF;

                    Template Toolkit Version 2.01
                    =============================
EOF

#------------------------------------------------------------------------
# check for pre-version 2.00 installation and issue warning
#------------------------------------------------------------------------

eval "use Template";
unless ($@ or $Template::VERSION =~ /^2/) {
    warn(<<EOF);

IMPORTANT NOTE:
---------------
    You have version $Template::VERSION of the Template Toolkit installed.

    There are some minor incompatabilities between version 1 and 2
    of the Template Toolkit which you should be aware of.  Installing
    this version will overwrite your version $Template::VERSION files
    unless you take measures to install one or the other version in a
    different location (i.e. perl Makefile.PL PREFIX=/other/path).  

    Please consult the README and Changes file for further details.
    Most of the changes are in the more obscure features and
    directives so hopefully you will find the upgrade process fairly
    painless.

EOF
    exit unless prompt("Do you want to continue?", 'y') =~ /y/i;
}

#------------------------------------------------------------------------
# detect mandatory module
#------------------------------------------------------------------------

eval "use AppConfig";
if ($@ or $AppConfig::VERSION < 1.52) {
    die(<<EOF);

The Template Toolkit requires that the AppConfig module (version 1.52
or later) first be installed.  This is used by the 'ttree' program for
reading command line options and configuration files.  It is available
from CPAN:

    http://www.cpan.org/authors/Andy_Wardley/

EOF
}

#------------------------------------------------------------------------
# detect additional modules required by plugins (just for fun)
#------------------------------------------------------------------------

print <<EOF;

The Template Toolkit includes a number of plugin modules, some of
which interface to external Perl modules available from CPAN.  All the
plugins will be installed regardless so that they will automatically
work as and when you install the relevant modules.  The tests will be
skipped for plugins that require external modules not currently
available on your system.

EOF

foreach my $mods ( [ Text::Autoformat => \&check_taf ],
		   [ XML::DOM   => \&check_dom   ],
		   [ XML::RSS   => \&check_rss   ],
		   [ XML::XPath => \&check_xpath ],
		   [ DBI        => \&dbi_config  ] ) {
    my ($module, $code) = ref $mods ? @$mods : ($mods, 0);

    printf("  %-16s ", $module);
    eval "use $module";
    if ($@) {
	nope("module not installed");
    }
    elsif ($code) {
	&$code;
    }
    else {
	no strict qw( refs );
	my $ver = ${"$module\::VERSION"};
	yep("version $ver installed");
    }
}

#------------------------------------------------------------------------
# prompt for installation of optional libraries and other components
#------------------------------------------------------------------------

print <<EOF;

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

if (prompt('Do you want to install these components?', 'y') =~ /^y/i) {
    print <<EOF;

You can chose any directory for the installation of the additional
Template Toolkit components.  The proposed default, $TT_INST_ROOT,
assumes a Unix flavour to your operating system (suggestions for suitable
defaults for other platforms welcome), but something like '/home/abw/tt2'
or 'C:/Program Files/tt2' may be more appropriate and would be equally valid.

EOF
    $TT_INST_ROOT = prompt('Template Toolkit installation directory',
			   $TT_INST_ROOT);
}
else {
    $TT_INST_ROOT = '';
}

fix_file('lib/Template/Config.pm', '$INSTDIR', $TT_INST_ROOT);


#------------------------------------------------------------------------
# prompt for Splash! image URL
#------------------------------------------------------------------------

if ($TT_INST_ROOT) {
    print <<EOF;

The Splash! template library uses a number of (very) small images to
build user interface components.  These will be installed into the
directory:

    $TT_INST_ROOT/images  

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

    $TT_IMAGES = prompt('URL base for TT2 images?', $TT_IMAGES);
    $TT_IMAGES =~ s[/$][]g;	# just in case
    fix_file('templates/splash/config', 'images', "$TT_IMAGES/splash");
}



if ($TT_INST_ROOT) {
    my $style = 'plain';
    my $style_cfg = '';

    #--------------------------------------------------------------------
    # prompt for HTML documentation build
    #--------------------------------------------------------------------
    print <<EOF;

The modules comprising the Template Toolkit contain comprehensive POD
documentation which can be browsed using 'perldoc' or 'man' (if your
system supports it).  In additional, the distribution also includes a
set of source templates and style elements for generating the same
documentation in HTML format.  These will be installed in the
directory:

    $TT_INST_ROOT/docs

The HTML documentation can be built for you at "make install" time in
a plain and simple HTML format or using the Splash! library.  You can
see examples of these different styles and browse the documentation
online at:

    http://www.template-toolkit.org/docs/

EOF

    $TT_BUILD_DOCS = ( 
	prompt('Do you want to build the HTML documentation?', 
	       $TT_BUILD_DOCS) =~ /^y/i 
    );

    #--------------------------------------------------------------------
    # prompt for docs style: plain or splash
    #--------------------------------------------------------------------

    if ($TT_BUILD_DOCS) {
	print <<EOF;

If you want to build the HTML documentation using then the Splash!
library then you'll need to make sure you correctly defined the URL
for the Splash!  images above.  Otherwise, answer 'n' to the next
question to use plain HTML.

EOF
	$TT_SPLASH_DOCS = ( 
	    prompt('Do you want to use the Splash! library?', 
		    $TT_SPLASH_DOCS) =~ /^y/i 
	);

	if ($TT_SPLASH_DOCS) {
	    $style = 'splash';
	    $style_cfg = "\npre_process  = splash/config";
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
src  = $TT_INST_ROOT/docs/src
dest = $TT_INST_ROOT/docs/html
lib  = $TT_INST_ROOT/docs/style/$style
lib  = $TT_INST_ROOT/docs/lib
lib  = $TT_INST_ROOT/templates
$style_cfg
pre_process  = config
pre_process  = header
post_process = footer
EOF
    close(FP);

    #--------------------------------------------------------------------
    # prompt for building examples
    #--------------------------------------------------------------------

    print <<EOF;

A number of examples showing use of the HTML, Splash! and PostScript 
libraries will be installed into:

    $TT_INST_ROOT/examples

As with the documentation, the examples are provided in template form
and can be automatically built into HTML pages during the "make
install".  These pages rely on the Splash! library and expect the
images URL to be correctly defined for correct viewing.

EOF

    $TT_EXAMPLES = ( 
	prompt('Do you want to build the HTML example pages?', 
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

src  = $TT_INST_ROOT/examples/src
dest = $TT_INST_ROOT/examples/html
lib  = $TT_INST_ROOT/examples/lib
lib  = $TT_INST_ROOT/templates
pre_process = config
ignore = ^(CVS|RCS)\$
EOF

    close(FP);
}

print "\n";

#------------------------------------------------------------------------ 
# build options and write Makefile
#------------------------------------------------------------------------

package MY;

sub postamble {
    return '' unless $TT_INST_ROOT;
    my $amble =<<'EOF';
tt2_install ::
	@$(PERL) bin/tt2inst -v $(TT_INST_ROOT)

EOF
    $amble .=<<EOF if $TT_BUILD_DOCS;
tt2_html_docs ::
	\@\$(PERL) bin/ttree -v -f \$(TT_INST_ROOT)/$TT_DOCS_CFG
EOF
    $amble .=<<EOF if $TT_EXAMPLES;
tt2_examples ::
	\@\$(PERL) bin/ttree -v -f \$(TT_INST_ROOT)/$TT_EXAMPLE_CFG
EOF
    return $amble;
}

sub install {
    my $class = shift;
    my $basic = $class->SUPER::install(@_);
    my $add   = 'tt2_install';
    $add .= ' tt2_html_docs' if $TT_BUILD_DOCS;
    $add .= ' tt2_examples' if $TT_EXAMPLES;
    $basic =~ s/^(install\s+::\s+.*)$/$1 $add/m
	if $TT_INST_ROOT;
    $basic;
}

sub constants {
    my $class = shift;
    my $basic = $class->SUPER::constants(@_);
    $basic = "TT_INST_ROOT = $TT_INST_ROOT\n$basic"
	if $TT_INST_ROOT;
    $basic;
}

package main;
    
my %opts = (
    'NAME'	   => 'Template',
    'DISTNAME'     => 'Template-Toolkit',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage', 'bin/ttree' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 'AppConfig' => 1.52 },
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
#	'PREOP'    =>  build_docs(),
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 
	'a fast, flexible and extensible template processing system',
}


WriteMakefile( %opts );

print <<EOF;

Configuration complete.  You should now run 'make', 'make test' and then
'make install'.  See the README file for further information.
EOF

print <<EOF if $TT_BUILD_DOCS;

Please note that the installation of the optional components and
building of the HTML documentation is performed at the "make install"
stage as the effective user at that time.  This implies that this user
must have sufficient permission to install into the specified
directory and that all created directories and files will be owned by
them.

EOF

#========================================================================


#------------------------------------------------------------------------
# build_docs()
#
# Echo the relevant incantation so that 'make dist' regenerates the 
# documentation from the template sources.
#------------------------------------------------------------------------

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)" ;           \\
\$(PERL) bin/ttree -f ./docs/ttdist.cfg --define version=\$(VERSION) -a;  \\
EOF
}


#------------------------------------------------------------------------
# yep($text)
# nope($text)
#------------------------------------------------------------------------

sub yep {
    print '[X] ', shift, "\n";
}

sub nope {
    print '[ ] ', shift, "\n";
}


#------------------------------------------------------------------------
# check_taf()
#
# There are some problems with Text::Autoformat with version of Perl 
# prior to 5.6.0 not working properly with locales that use a numerical 
# separator other than '.' (e.g. Swedish)
#------------------------------------------------------------------------

sub check_taf {
    use POSIX qw( localeconv );
    my $loc = localeconv;
    my $dec = $loc->{ decimal_point };

    yep("version $Text::Autoformat::VERSION installed");

    if ($] <= 5.006 && $dec ne '.') {
	print ' ' x 6, 
	"NOTE: tests 23 and 25 may fail under your locale, see TODO file.\n";
    }
}


#------------------------------------------------------------------------
# check_dom()
#
# XML::DOM changed from HASH to ARRAY objects somewhere between versions
# 1.25 and 1.27, so the latter version is an absolute necessity.
#------------------------------------------------------------------------

sub check_dom {
    if ($XML::DOM::VERSION < 1.27) {
	nope("requires version 1.27 or later ($XML::DOM::VERSION installed)");
    }
    else {
	yep("version $XML::DOM::VERSION installed");
    }
}


#------------------------------------------------------------------------
# check_rss()
#
# Version 0.8 of XML::RSS gave warnings under Perl 5.6.0 so issue an 
# upgrade recommendation
#------------------------------------------------------------------------

sub check_rss {
    if ($] >= 5.006 && $XML::RSS::VERSION < 0.9) {
	nope("requires version 0.9 or later ($XML::RSS::VERSION installed)");
    }
    else {
	yep("version $XML::RSS::VERSION installed");
    }
}

#------------------------------------------------------------------------
# check_xpath()
#
# Tests fail under some of the earlier versions (e.g. 0.55) so we issue
# an upgrade recommendation.
#------------------------------------------------------------------------

sub check_xpath {
    if ($XML::XPath::VERSION < 1.00) {
	nope("requires version 1.00 or later ($XML::XPath::VERSION installed)");
    }
    else {
	yep("version $XML::XPath::VERSION installed");
    }
}


#------------------------------------------------------------------------
# dbi_config()
#
# Quiz the user for options related to running the DBI tests.
#------------------------------------------------------------------------

sub dbi_config {
    my ($dsn, $user, $pass, $run);
    $run = 1;

    print "[X] version $DBI::VERSION installed, configuring tests\n\n";

    if (prompt("Do you want to run the DBI tests?\n" .
	       "It requires access to an existing test database.",
	       "y") =~ /y/i) {

	my ($driver, $dbname);
	my @drivers = DBI->available_drivers();
	local $" = ', ';

	my $default = (grep(/m.?sql/i, @drivers))[0];
	
	print <<EOF;

Please enter the driver name for the test database.
The DBD drivers installed on your system are

    @drivers

EOF

	while (! $driver) {
	    $driver = prompt("Enter driver name: ", $default);
	    print("! No such DBD driver\n"), undef $driver
		unless grep(/^$driver$/, @drivers);
	}

	print <<EOF;

Now enter the data source (DSN) for the test database.
Many DBD drivers require only a database name (e.g. 'test') while
others may require an alternate format or additional parameters
(e.g. 'dbname=test').  Please consult your DBD documentation for
further details.

EOF

	my $dbname_eg = $driver eq 'Pg' ? 'dbname=test' : 'test';
	while (! $dbname) {
	    $dbname = prompt('Database name: ', $dbname_eg);
	}
    
	$dsn = "dbi:$driver:$dbname";

	$user = prompt('Enter user name : ', '');
	$pass = prompt('Enter password  : ', '');

	$user = '' unless defined $user;
	$pass = '' unless defined $pass;
    }
    else {
	$run = 0;
    }

    print "\nwriting $DBI_CONFIG_FILE\n";
    open(CFGFILE, ">$DBI_CONFIG_FILE") || die "$DBI_CONFIG_FILE: $!\n";
    print CFGFILE <<EOF;
\$run  = $run;
\$dsn  = '$dsn';
\$user = '$user';
\$pass = '$pass';
1;
EOF
    close(CFGFILE);
}



#------------------------------------------------------------------------
# fix_file($file, $find, $fix)
#
# Fixes a variable definition in a file.  e.g. 
# fix_file('lib/Template/Config.pm', '$INSTDIR', '/usr/local/tt2')
#------------------------------------------------------------------------

sub fix_file {
    my ($file, $find, $fix) = @_;
    local *FP;
    local $/ = undef;

#    print "\nSetting $find in $file to '$fix'\n\n";
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


