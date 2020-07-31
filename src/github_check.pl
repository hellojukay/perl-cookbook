#!/bin/perl
# 从 github 的 api 接口获取所有的 github ip 地址
# github api 参考文档地址: https://docs.github.com/cn/rest/reference/meta
# curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/meta

use warnings;
use strict;

use HTTP::Tiny;
use JSON;
use Time::HiRes qw(gettimeofday);

# 返回 github 的所有 ip 地址
sub request_github {
    my $response = HTTP::Tiny->new->get(
        'https://api.github.com/meta',
        {
            headers => { 'Accept' => 'plication/vnd.github.v3+json"' }
        }
    );
    if ( $response->{status} != 200 ) {
        die "github response code  $response->{status}";
    }

    my $content      = $response->{content};
    my $json         = JSON->new->allow_nonref;
    my $response_obj = $json->decode($content);

    my @ips = @{ $response_obj->{git} };
    push @ips, @{ $response_obj->{web} };

    my @result;
    foreach my $ip (@ips) {

        # 原 ip 格式为 "192.30.252.0/22",
        my ( $ip, $mask ) = split( /\//, $ip );
        push @result, $ip;
    }
    return @result;
}

sub check_http {
    my $ip = $_[0];
    my ( $start_sec, $start_mcsecond ) = gettimeofday();
    my $response = HTTP::Tiny->new->get("http://$ip");
    $_ = $response->{content};
    my ( $end_sec, $end_mcsecond ) = gettimeofday();
    return ( $end_sec - $start_sec ) +
      ( $end_mcsecond - $start_mcsecond ) / ( 1000 * 1000 );
}

sub check_ssh {
    my $ip = $_[0];
}
sub check_icmp {
    my $host = $_[0];
    my $p = Net::Ping->new();
    $p->hires();
    my ($ret , $duraiton, $ip) = $p->ping($host,5.5);
    printf "$ip %s ms\n",$duraiton * 1000;
}
my @ips = request_github();
foreach my $ip (@ips) {
    check_icmp($ip);
}

