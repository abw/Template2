# $Id$

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Template::Stash::XS',
    'C'        => [ qw( Stash.c ) ],
    'XS'       => { 'Stash.xs' => 'Stash.c' },
    'OBJECT'   => 'Stash.o',
    'VERSION'  => '2.05b',
    'NORECURS' => 1,
    'MAN3PODS' => 'none'
);

