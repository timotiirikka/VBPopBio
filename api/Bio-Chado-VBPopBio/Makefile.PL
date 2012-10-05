use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::Chado::VBPopBio',
    AUTHOR              => q{VectorBase <info@vectorbase.org>},
    VERSION_FROM        => 'lib/Bio/Chado/VBPopBio.pm',
    ABSTRACT            => 'A module to simplify dealing with the GMOD Chado Natural Diversity Schema',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'DBIx::Class::DynamicSubclass' => 0,
	'Bio::Parser::ISATab' => 0,
        'Iterator::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-Chado-VBPopBio-*' },
);
