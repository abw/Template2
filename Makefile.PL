use ExtUtils::MakeMaker;				    # -*-perl-*-

my $man3pods = {
    map { ("docs/pod/$_.pod" => "\$(INST_MAN3DIR)/Template::$_.\$(MAN3EXT)") }
    qw( Base Config Constants Context Document Exception Filters 
	Iterator Parser Plugin Plugins Provider Service Stash 
	Test Utils )
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

