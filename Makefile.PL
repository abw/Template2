use ExtUtils::MakeMaker;				    # -*-perl-*-

select STDERR;
$| = 1;
select STDOUT;

# beep!
print STDERR "\a";

eval "use Template";
unless ($@) {
    warn(<<EOF);
IMPORTANT NOTE:

    Version $Template::VERSION of the Template Toolkit detected.

    This installation will most likely trash that version and render
    it totally useless.  You probably don't want that to happen right
    now, so please ensure that you install this beta release into a
    separate directory.  These co-existance problems will be solved
    for version 2.00 proper.

    If you are suitably wise and have issued the appropriate command 
    line incantation to ensure that this bundle is installed to a safe
    location, e.g.

	perl Makefile.PL LIB=/some/other/place

    then we apologise.  This script is too dumb to recognise the fact
    and must issue this tedious warning regardless.

EOF
}

warn(<<EOF);
    This is beta code.  Please read the README and Changes files for 
    details of the current status.

EOF



my $man3pods = {
    map { ("docs/pod/$_.pod" => "\$(INST_MAN3DIR)/Template::$_.\$(MAN3EXT)") }
    qw( Base Config Constants Context Document Exception Filters 
	Iterator Parser Plugin Plugins Provider Service Stash Test )
};
$man3pods->{'docs/pod/Template.pod'} = '$(INST_MAN3DIR)/Template.$(MAN3EXT)';

WriteMakefile(
    'NAME'	   => 'Template',
    'DISTNAME'     => 'Template-Toolkit',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage', 'bin/ttree' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 'AppConfig' => 1.52 },
    'MAN3PODS'	   => $man3pods,
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
	'PREOP'    =>  build_docs(),
    },
);

#   'DIR'	   => [ 'clib' ],

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)" ;           \\
\$(PERL) bin/ttree -f ./docs/ttree.cfg -a;                        \\
EOF
}


# Could add these before/after call to ttree to write-protect output docs
# to prevent accidental editing.  Better to edit the source files...
# \$(CHMOD) 644 docs/pod/*.pod;                                     \\
# \$(CHMOD) 444 docs/pod/*.pod;                                     \\

