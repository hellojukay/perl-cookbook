#!/bin/perl

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);
use Net::Ping;
use threads;
use threads::shared;
use HTTP::Tiny;

# 从 github 的 api 接口获取所有的 github ip 地址
# github api 参考文档地址: https://docs.github.com/cn/rest/reference/meta
# curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/meta
my @ips = qw(
   192.30.252.0
   185.199.108.0
   140.82.112.0
   13.114.40.48
   52.192.72.89
   52.69.186.44
   15.164.81.167
   52.78.231.108
   13.234.176.102
   13.234.210.38
   13.229.188.59
   13.250.177.223
   52.74.223.119
   13.236.229.21
   13.237.44.5
   52.64.108.95
   18.228.52.138
   18.228.67.229
   18.231.5.6
   18.181.13.223
   54.238.117.237
   54.168.17.15
   3.34.26.58
   13.125.114.27
   3.7.2.84
   3.6.106.81
   18.140.96.234
   18.141.90.153
   18.138.202.180
   52.63.152.235
   3.105.147.174
   3.106.158.203
   54.233.131.104
   18.231.104.233
   18.228.167.86
);
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
    printf "%-18s %2.2fs \n",$ip , $duraiton;
}

my $count :shared;
$count = $#ips;
foreach my $ip (@ips) {
    threads->new(sub{
        check_icmp($_[0]);
        {
            lock($count);
            $count = $count -1
        }
    },$ip)->detach();
}
while(1) {
    unless($count) {
        exit(0);
    }
}
