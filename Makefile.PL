use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME              => 'Sys::Signals::Block',
    VERSION_FROM      => 'lib/Sys/Signals/Block.pm',
    PREREQ_PM         => {
        'Class::Accessor' => 0,
        'Test::More'      => 0,
        'Test::Exception' => 0
    },
    ABSTRACT_FROM  => 'lib/Sys/Signals/Block.pm',
    AUTHOR         => 'Michael J Schout <mschout@cpan.org>'
);
