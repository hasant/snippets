#!/usr/bin/perl

=head1 NAME

limitcpu - cpu usage limiter that can be run forever in background

=head1 DESCRIPTION

A simple script to monitor CPU usage and limit CPU usage of cetain
processes when they exceed pre-determined threshold. I plan some
improvements. Let's see which one(s) and when.

It's usable at its current state, at least it does what I need.

=head1 REQUIREMENTS

=over

=item Perl

To run this script.

=item top

To obtain the process list of the system. We could use extra module
for portability, but right now no, not really.

=item cpulimit

The program that actually enforces the CPU usage limit on the target
process. URL: https://github.com/opsengine/cpulimit

=item root access

The cpulimit program requires root privilege to execute.

=back

=head1 DISCLAIMER

Use at your own RISK. I assume neither liability nor responsibility
for any direct damage or side effect of using this script.

=head1 AUTHOR

Hasanuddin Tamir E<lt>hasant at gmail dot comE<gt>

=head1 SOME PLANS

    In no particular order:

    exit at certain conditions and schedule to self-restart

    exit at certaint conditions. just exits, nothing else

    daemonize

    check another instance of self

    logging

    options, more options

    flexible threshold

    specific targets by command name

    blacklist/whitelist

    portability is not part of the plan

=cut

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

my $cpu_limit = 80;
my $low_threshold = 10;
my $num_of_low_usage = 5;

sub check_process {
    my $IN = 0;
    my $caught = 0;
    my $low_usage = 0;

    chomp(my @toplines = qx/top -bn 1/);
    for (@toplines) {
        if (/PID\s+USER/) {
            # we're on
            $IN = 1;
            next;
        }
        $IN || next;

        my @parts = split ' ', $_, 12;
        if ($parts[8] > $cpu_limit) {
            system qw(cpulimit -b -l $cpu_limit -p $parts[0]);
            print STDERR "limiting cpu usage for [$parts[11]] from [$parts[8]] to $cpu_limit\n";
            $caught++;
        }

        if ($parts[8] < $low_threshold) {
            if ($low_usage++ == $num_of_low_usage) {
                print STDERR "num of low usage ($num_of_low_usage) reached, stopping...\n";
                last;
            }
        }
    }

    $caught;
}

while (1) {
    my $caught = check_process();
    sleep 120;

    #TODO: if we get $caught=0 X times in a row, we need to exit
    #      and wake up ourself in a Y hours/minutes (with at)
    #      OR, just exit when it's due and use cron to run it again
}
