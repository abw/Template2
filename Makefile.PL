use ExtUtils::MakeMaker;


WriteMakefile(
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

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)" ;           \\
\$(RM_F) lib/Template.pod lib/Template/Tutorial.pod ;             \\
\$(PERL) doc/bin/mkdoc README.pod | pod2text > README ;           \\
\$(PERL) doc/bin/mkdoc Template.pod > lib/Template.pod ;          \\
\$(PERL) doc/bin/mkdoc Tutorial.pod > lib/Template/Tutorial.pod ; \\
\$(CHMOD) 444 lib/Template.pod;                                   \\
\$(CHMOD) 444 lib/Template/Tutorial.pod                           \\
EOF
}


