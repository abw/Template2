use ExtUtils::MakeMaker;				    # -*-perl-*-

select STDERR;
$| = 1;
select STDOUT;

warn(<<EOF);

    Template Toolkit Version 2.00 beta 4
    ------------------------------------

    This is stable beta code and a release candidate for Version 2.00 
    proper.  Please read the README file and consult the Changes and 
    TODO files for further information.

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
    that have changed from version 1.xx to 2.xx then go ahead, be
    bold.  The Changes file contains details of visible changes from
    versions 1.xx and 2.xx beta releases and highlights some issues
    that you you might need to attend to.  The TODO file contains
    details of the (very few) known bugs, problems, limitations, etc.

    If you want to install the Template Toolkit to an alternate 
    directory when you can do it like this:

        perl Makefile.PL PREFIX=/some/where/else

    Remember to add "use lib '/some/where/else'" to your Perl scripts
    so that they can find and load the relevant modules.

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

