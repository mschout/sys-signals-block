package Sys::Signals::Block;

use 5.008;
use strict;
use base qw(Class::Accessor::Fast);

use Carp qw(croak);
use POSIX qw(sigprocmask SIG_BLOCK SIG_UNBLOCK);

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(sigset is_blocked));

sub import {
    my $class = shift;

    # TODO: map signal names to values

    if (@_) {
        my $sigset = POSIX::SigSet->new(@_)
            or croak "Can't create SigSet: $!";
        $class->instance->sigset($sigset);
    }
}

my $Instance;

sub instance {
    my $class = shift;

    unless ( defined $Instance ) {
        $Instance = $class->new({ is_blocked => 0 });
    }

    return $Instance;
}

sub block {
    my $self = shift->instance;

    return if $self->is_blocked;

    my $retval = sigprocmask(SIG_BLOCK, $self->sigset);

    if ($retval) {
        $self->is_blocked(1);
    }

    return $retval;
}

sub unblock {
    my $self = shift->instance;

    return unless $self->is_blocked;

    my $retval = sigprocmask(SIG_UNBLOCK, $self->sigset);

    if ($retval) {
        $self->is_blocked(0);
    }

    return $retval;
}

1;

__END__

=head1 NAME

Sys::Signals::Block - Simple interface to block delivery of signals

=head1 SYNOPSIS

  use Sys::Signals::Block qw(TERM INT);

  Sys::Signals::Block->block;
  # critical section.
  # SIGINT, SIGTERM will not be delivered
  Sys::Signals::Block->unblock;
  # signals sent during critical section will be delivered here

  # or if you prefer object syntax:
  my $sigs = Sys::Signals::Block->instance;

  $sigs->block;
  # critical section
  $sigs->unblock;

=head1 DESCRIPTION

This module provides an easy way to block the delivery of certain signals.
This is essentially just a wrapper around C<POSIX::sigprocmask(SIG_BLOCK, ...)>
and C<POSIX::sigprocmask(SIG_UNBLOCK, ...)>, but with a much simpler API.

=head1 METHODS

All methods can be called either as class methods, or as object methods on the
C<<Sys::Signals::Block->instance>> object.

=over 4

=item instance()

Returns the instance of this module.

=item block()

Blocks the set of signals given in the C<use> line.

=item unblock()

Unblocks the set of signals given in the C<use> line.  Any signals that were
not delivered while signals were blocked will be delivered once the signals are
unblocked.

=back

=head1 TODO

=over 4

=item *

Add ability to change the set of signals that should be blocked at runtime.

=back

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/sys-signals-block

 git clone git://github.com/mschout/sys-signals-block.git

=head1 BUGS

Please report any bugs or feature requests to
bug-sys-signals-block@rt.cpan.org, or through the web interface at
http://rt.cpan.org/.

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Michael Schout

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=head1 SEE ALSO

L<POSIX/SigSet>, L<POSIX/sigprocmask>

=cut
