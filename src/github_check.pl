#!/bin/perl

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);
use Net::Ping;
use threads;
use threads::shared;
use HTTP::Tiny;
use IO::Socket;

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

sub check_icmp {
    my $host = $_[0];
    my $p = Net::Ping->new();
    $p->hires();
    my ($ret , $duraiton, $ip) = $p->ping($host,30);
    $p->close();
    if(!defined($ret)){
        return "TIMEOUT"
    }
    return sprintf("%2.2fs",$duraiton);
}

# 检查 ssh 延时, 尝试链接服务器 22 端口，并且读取一个字节
# 返回 2 个值，($ok,$time), $ok 表示是否链接成功，$time 表示链接耗时
sub check_ssh {
    my $sock = IO::Socket::INET->new(
        Proto => "tcp",
        PeerAddr => $_[0],
        PeerPort => 22,
    );
    my ( $ssh_start_sec, $ssh_start_mcsecond ) = gettimeofday();
    my $buf;
    my $len = 1;
    if(!defined($sock)){
        return "TIMEOUT";
    }
    $sock->sysread($buf,$len);
    my ($ssh_end_sec, $ssh_end_mcsecond ) = gettimeofday();
    my $ssh_time = ($ssh_end_sec - $ssh_start_sec) + ($ssh_end_mcsecond - $ssh_start_mcsecond) / (1000*1000);
    return sprintf("%2.2fs",$ssh_time);
}
my $count :shared;
$count = $#ips;
printf "%-20s%-10s%-10s\n","IP", "SSH","ICMP";
foreach my $ip (@ips) {
    threads->new(sub{
        my $host = $_[0];
        my $ssh_duration = check_ssh($host);
        my $ping_duration = check_icmp($host);
        printf "%-20s%-10s%-10s\n",$host,$ssh_duration,$ping_duration;
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
