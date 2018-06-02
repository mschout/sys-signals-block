package Sys::Signals::Block;

# ABSTRACT: Simple interface to block delivery of signals

use 5.008;
use strict;
use warnings;

use Moo;
use strictures 2;
use Carp qw(croak);
use POSIX qw(sigprocmask SIG_BLOCK SIG_UNBLOCK);
use namespace::clean;

=method sigset(): POSIX::SigSet

Get the set of signals that will be blocked.

=cut

has sigset => (is => 'rw');


=method is_blocked(): bool

Return C<true> if the set of signals are currently blocked, C<false> otherwise.

=cut

has is_blocked => (is => 'rw');

# maps signal names to signal numbers
has signal_numbers => (is => 'lazy');

sub import {
    my $class = shift;

    if (@_) {
        my $instance = $class->instance;

        my @sigs = $instance->parse_signals(@_)
            or croak "no valid signals listed on import line";

        my $sigset = POSIX::SigSet->new(@sigs)
            or croak "Can't create SigSet: $!";

        $instance->sigset($sigset);
    }
}

sub _build_signal_numbers {
    my $self = shift;

    require Config;

    my @names = split /\s+/, $Config::Config{sig_name};
    my @nums  = split /[\s,]+/, $Config::Config{sig_num};

    my %sigs;

    @sigs{@names} = @nums;

    return \%sigs;
}

sub parse_signals {
    my ($self, @signals) = @_;

    my @nums;

    for my $signal (@signals) {
        unless ($signal =~ /\D/) {
            push @nums, $signal;
        }
        else {
            $signal =~ s/^SIG//;

            my $num = $self->signal_numbers->{$signal};

            unless (defined $num) {
                croak "invalid signal name: 'SIG${signal}'";
            }

            push @nums, $num;
        }
    }

    return @nums;
}

=method instance(): scalar

Returns the instance of this module.

=cut

my $Instance;

sub instance {
    my $class = shift;

    unless ( defined $Instance ) {
        $Instance = $class->new(is_blocked => 0);
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

=for Pod::Coverage signal_numbers parse_signals

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
