use ExtUtils::MakeMaker;				    # -*-perl-*-

select STDERR;
$| = 1;
select STDOUT;

my $DBI_CONFIG_FILE = 't/dbi_test.cfg';

print <<EOF;

                    Template Toolkit Version 2.00
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

print "\n";

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

print <<EOF;

Configuration complete.  You should now run 'make', 'make test' and then
'make install'.  Please don't forget to read the README file.

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

    print "[X] version $DBI::VERSION installed, configuring tests\n";

    if (prompt("  - Do you want to run the DBI tests?\n" .
	       "    It requires access to an existing test database.",
	       "y") =~ /y/i) {

	my ($driver, $dbname);
	my @drivers = DBI->available_drivers();
	local $" = ', ';

	my $default = (grep(/m.?sql/i, @drivers))[0];
	
	print <<EOF;
  - Please enter the driver name for the test database.
    The DBD drivers installed on your system are

      @drivers

EOF

	while (! $driver) {
	    $driver = prompt("  - Enter driver name: ", $default);
	    print("    No such DBD driver\n"), undef $driver
		unless grep(/^$driver$/, @drivers);
	}

	print <<EOF;
  - Please enter the data source (DSN) of the test database.
    Many DBD drivers require only a database name (e.g. 'test') while
    others may require an alternate format or additional parameters
    (e.g. 'dbname=test').  Please consult your DBD documentation for
    further details.
EOF

	my $dbname_eg = $driver eq 'Pg' ? 'dbname=test' : 'test';
	while (! $dbname) {
	    $dbname = prompt('  - Database name: ', $dbname_eg);
	}
    
	$dsn = "dbi:$driver:$dbname";

	$user = prompt('  - Enter user name : ', '');
	$pass = prompt('  - Enter password  : ', '');

	$user = '' unless defined $user;
	$pass = '' unless defined $pass;
    }
    else {
	$run = 0;
    }

    print "  - writing $DBI_CONFIG_FILE\n";
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

