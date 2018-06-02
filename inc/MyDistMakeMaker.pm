package inc::MyDistMakeMaker;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;

    my $template = <<'TEMPLATE';
    eval {
        require POSIX;
        POSIX::SigSet->new;
    };
    if ($@) {
        die "This module requires POSIX signals.",
            "Your platform does not implement them, sorry.\n";
    }
TEMPLATE

    $template .= super();

    return $template;
};

__PACKAGE__->meta->make_immutable;
