use ExtUtils::MakeMaker;				    # -*-perl-*-

select STDERR;
$| = 1;
select STDOUT;

warn(<<EOF);
    Template Toolkit Version 2.00 beta 3
    ------------------------------------

    This is stable beta code.  Please read the README and Changes files.

EOF


eval "use Template";
unless ($@) {
    warn(<<EOF) unless $Template::VERSION =~ /^2/;
    IMPORTANT NOTE:
    --------------

    Version $Template::VERSION of the Template Toolkit detected.

    If you install these modules you will totally screw up your
    Version $Template::VERSION installation.  If you're ready to take
    the plunge and aren't relying too heavily on any of the "features"
    that have changed from version 1.xx to 2.xx (see Changes file),
    then go ahead.  Be bold.  See the Changes file for a summary of
    all the great new things for you to play with, and the issues that
    you might need to attend to.

    You might then decide to re-install Version $Template::VERSION to a different
    location in case you ever need it, e.g.

        perl Makefile.PL PREFIX=/some/where/else

    Remember to add "use lib '/some/where/else'" to your Perl scripts
    that want to use Version 1.07, and also to the V1 'tpage' and
    'ttree' scripts (in /some/where/else/bin) so that they continue to
    use the right versions of the modules.

    Alternatively, you can install this Version 2.00 beta to a
    different location and follow the strategy outlined above, or not
    "make install" it at all.

EOF
}


# my $man3pods = {
#     map { ("docs/pod/$_.pod" 
# 	  => "\$(INST_MAN3DIR)/Template::$_.\$(MAN3EXT)") }
#     qw( Base Config Constants Context Document Exception Filters 
# 	  Iterator Parser Plugin Plugins Provider Service Stash Test )
# };
# $man3pods->{'docs/pod/Template.pod'} = '$(INST_MAN3DIR)/Template.$(MAN3EXT)';

my %opts = (
    'NAME'	   => 'Template',
    'DISTNAME'     => 'Template-Toolkit',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage', 'bin/ttree' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 'AppConfig' => 1.52 },
#    'MAN3PODS'	   => $man3pods,
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


#------------------------------------------------------------------------

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)" ;           \\
\$(PERL) bin/ttree -f ./docs/ttdist.cfg --define version=\$(VERSION) -a;  \\
EOF
}

