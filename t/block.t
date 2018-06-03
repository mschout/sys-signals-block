#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use POSIX qw(SIGHUP SIGUSR1);
use Sys::Signals::Block qw(SIGHUP SIGUSR1);
use My::Test::SignalHandlers;
use Test::More tests => 4;

Sys::Signals::Block->block;

kill SIGHUP, $$;
kill SIGUSR1, $$;

# sleep 1s so that we wait to make sure the signals are blocked.
sleep 1;

ok !$HUP, 'SIGHUP was blocked';
ok !$USR1, 'SIGUSR1 was blocked';

Sys::Signals::Block->unblock;
# signals should be delivered here.

ok $HUP, 'SIGHUP was delivered';
ok $USR1, 'SIGUSR1 was delivered';
