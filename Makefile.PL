use ExtUtils::MakeMaker;				    # -*-perl-*-

select STDERR;
$| = 1;
select STDOUT;

my $DBI_CONFIG_FILE = 't/dbi_test.cfg';

print <<EOF;
Template Toolkit Version 2.00
-----------------------------
EOF

#------------------------------------------------------------------------
# check for pre-version 2.00 installation and issue warning
#------------------------------------------------------------------------

eval "use Template";
unless ($@ or $Template::VERSION =~ /^2/) {
    warn(<<EOF);
IMPORTANT NOTE:

    You have version $Template::VERSION of the Template Toolkit installed.

    There are some minor incompatabilities between version 1.* and 2.*
    of the Template Toolkit which you should be aware of.  Installing
    this version will overwrite your version $Template::VERSION files
    unless you take measures to install one or the other version in a
    different location (i.e. perl Makefile.PL LIB=/other/path).  

    Please consult the README and Changes file for further details.
    Most of the changes are in the more obscure features and
    directives so hopefully you will find the upgrade process fairly
    painless.

EOF
    exit unless prompt("Do you want to continue?", 'y') =~ /y/i;
}

#------------------------------------------------------------------------
# detect additional modules required by plugins (just for fun)
#------------------------------------------------------------------------

print <<EOF;

The Template Toolkit includes a number of plugin modules, some of which 
interface to external Perl modules available from CPAN.  All the plugins
will be installed regardless (so that they will work automatically if and
when you install the relevant modules) but the tests will be skipped for 
plugins that require external modules not available on your system.

EOF

foreach my $mods ( [ XML::DOM   => \&check_dom   ],
		   [ XML::RSS   => \&check_rss   ],
		   [ XML::XPath => \&check_xpath ],
		   [ DBI        => \&dbi_config  ] ) {
    my ($module, $code) = @$mods;

    printf("  %-12s - ", $module);
    eval "use $module";
    if ($@) {
	print "skipping test (module not installed)\n";
    }
    else {
	&$code;
    }
}


#------------------------------------------------------------------------ 
# build options and write Makefile
#------------------------------------------------------------------------

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
	'PREOP'    =>  build_docs(),
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 
	'a fast, flexible and extensible template processing system',
}

WriteMakefile( %opts );


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
# check_dom()
#
# XML::DOM version 1.25 (and earlier?) dump core with Perl 5.6.0
#------------------------------------------------------------------------

sub check_dom {
    if ($] == 5.006 && $XML::DOM::VERSION <= 1.25) {
	print "version $XML::DOM::VERSION may not work with Perl $], skipping\n";
    }
    else {
	print "version $XML::DOM::VERSION installed, including tests\n";
    }
}


#------------------------------------------------------------------------
# check_rss()
#
# Version 0.8 of XML::RSS gave warnings under Perl 5.6.0 so issue an 
# upgrade recommendation
#------------------------------------------------------------------------

sub check_rss {
    if ($] == 5.006 && $XML::RSS::VERSION < 0.9) {
	print "please upgrade to version 0.9 or later ($XML::RSS::VERSION installed)\n";
    }
    else {
	print "version $XML::RSS::VERSION installed, including tests\n";
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
	print "please upgrade to version 1.00 or later ($XML::XPath::VERSION installed)\n";
    }
    else {
	print "version $XML::XPath::VERSION installed, including tests\n";
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

    print "version $DBI::VERSION installed, configuring tests\n";

    if (prompt("- Do you want to run the DBI tests?\n" .
	       "  It requires access to an existing test database.",
	       "y") =~ /y/i) {

	my ($driver, $dbname);
	my @drivers = DBI->available_drivers();
	local $" = ', ';

	my $default = (grep(/m.?sql/i, @drivers))[0];

	print "- Please enter the driver name for the test database.\n";
	print "  The DBD drivers installed on your system are\n\n";
	print "      @drivers\n\n";

	while (! $driver) {
	    $driver = prompt("- Enter driver name: ", $default);
	    print("! No such DBD driver\n"), undef $driver
		unless grep(/^$driver$/, @drivers);
	}

	while (! $dbname) {
	    $dbname = prompt('- Enter database name: ', 'test');
	}
    
	$dsn = "dbi:$driver:$dbname";

	$user = prompt('- Enter user name : ', '');
	$pass = prompt('- Enter password  : ', '');

	$user = '' unless defined $user;
	$pass = '' unless defined $pass;
    }
    else {
	$run = 0;
    }

    print "- writing $DBI_CONFIG_FILE\n";
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

