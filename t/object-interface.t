#!/usr/bin/env perl
#

use strict;
use warnings;
use lib 't/lib';
use My::Test::SignalHandlers;
use POSIX qw(SIGHUP SIGUSR1);
use Sys::Signals::Block;
use Test::More tests => 9;

my $obj = new_ok 'Sys::Signals::Block', [qw(SIGHUP SIGUSR1)];

ok !$HUP;
ok !$USR1;

# check that signal delivery is working.
kill SIGHUP, $$;
kill SIGUSR1, $$;

cmp_ok $HUP, '==', 1;
cmp_ok $USR1, '==', 1;

# block signals
$obj->block;

kill SIGHUP, $$;
kill SIGUSR1, $$;

sleep 1;

# check that signals were not delivered yet
cmp_ok $HUP, '==', 1;
cmp_ok $USR1, '==', 1;

$obj->unblock;

# check that signals were delivered
cmp_ok $HUP, '==', 2;
cmp_ok $USR1, '==', 2;
