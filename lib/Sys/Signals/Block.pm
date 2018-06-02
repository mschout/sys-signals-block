package Sys::Signals::Block;

# ABSTRACT: Simple interface to block delivery of signals

use 5.008;
use strict;
use base qw(Class::Accessor::Fast);

use Carp qw(croak);
use POSIX qw(sigprocmask SIG_BLOCK SIG_UNBLOCK);

__PACKAGE__->mk_accessors(qw(sigset is_blocked));

# mapping of signame => number
my %SigNum = _get_signums();

sub import {
    my $class = shift;

    if (@_) {
        my @sigs = $class->_parse_signals(@_)
            or croak "no signals listed on import line";

        my $sigset = POSIX::SigSet->new(@sigs)
            or croak "Can't create SigSet: $!";

        $class->instance->sigset($sigset);
    }
}

# convert signal names to numbers
sub _get_signums {
    require Config;

    my @names = split /\s+/, $Config::Config{sig_name};
    my @nums  = split /[\s,]+/, $Config::Config{sig_num};

    my %sigs;
    @sigs{@names} = @nums;

    return %sigs;
}

sub _parse_signals {
    my ($class, @signals) = @_;

    my @nums;

    for my $signal (@signals) {
        unless ($signal =~ /\D/) {
            push @nums, $signal;
        }
        else {
            $signal =~ s/^SIG//;
            my $num = $SigNum{$signal};
            unless (defined $num) {
                croak "invalid signal name: 'SIG${signal}'";
            }

            push @nums, $num;
        }
    }

    return @nums;
}

my $Instance;

=method instance(): scalar

Returns the instance of this module.

=cut

sub instance {
    my $class = shift;

    unless ( defined $Instance ) {
        $Instance = $class->new({ is_blocked => 0 });
    }

    return $Instance;
}

=method block(): void

Blocks the set of signals given in the C<use> line.

=cut

sub block {
    my $self = shift->instance;

    return if $self->is_blocked;

    my $retval = sigprocmask(SIG_BLOCK, $self->sigset);

    if ($retval) {
        $self->is_blocked(1);
    }

    return $retval;
}

=method unblock(): void

Unblocks the set of signals given in the C<use> line.  Any signals that were
not delivered while signals were blocked will be delivered once the signals are
unblocked.

=cut

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

The set of signals that should be blocked are given in the import list (the
parameters in the C<use> line for the module).  The signal values can be either
numeric, or string names.  If names are given, they may be given either with or
without the C<SIG> prefix.  For example, the following are all equivalent:

 # names, no SIG prefix
 use Sys::Signals::Block qw(TERM INT);

 # names with SIG prefix
 use Sys::Signals::Block qw(SIGTERM SIGINT);

 # integers, using POSIX constants
 use Sys::Signals::Block (POSIX::SIGTERM, POSIX::SIGINT);

All methods can be called either as class methods, or as object methods on the
C<<Sys::Signals::Block->instance>> object.

=head1 TODO

=for :list
* Add ability to change the set of signals that should be blocked at runtime.

=head1 SEE ALSO

L<POSIX/SigSet>, L<POSIX/sigprocmask>

=cut
