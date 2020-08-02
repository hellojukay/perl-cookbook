#!/bin/perl

use warnings;
use strict;

use Time::HiRes qw(gettimeofday);
use Net::Ping;
use threads;
use threads::shared;
use HTTP::Tiny;
use IO::Socket;
use LWP::Simple;
use JSON::PP;
use Class::Struct;
struct(GitHub => {
    web => '@',
    git => '@',
});

# 从 github 的 api 接口获取所有的 github ip 地址
# github api 参考文档地址: https://docs.github.com/cn/rest/reference/meta
# curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/meta
sub github_ip{
    my $content = get("https://api.github.com/meta");
    if($content) {
        my @web_ip;
        my @git_ip;
        my $response = decode_json $content;
        my @web      = @{$response->{web}};
        my @git      = @{$response->{git}};
        foreach my $ip_with_mask (@web) {
            my ($ip,$mask) = split /\//, $ip_with_mask;
            push @web_ip, $ip;
        }
        foreach my $ip_with_mask (@git) {
            my ($ip,$mask) = split /\//, $ip_with_mask;
            push @git_ip, $ip;
        }
        return GitHub->new(web=>\@web_ip,git => \@git_ip);
    }else {
        print "network failure\n";
        exit 1;
    }
}
print "waiting https://api.github.com/meta ...";
sub check_http {
    my $ip = $_[0];
    my ( $start_sec, $start_mcsecond ) = gettimeofday();
    my $response                       = HTTP::Tiny->new->get("https://$ip");
    $_                                 = $response->{content};
    my ( $end_sec, $end_mcsecond )     = gettimeofday();
    return sprintf("%2.2f",(( $end_sec - $start_sec ) + ( $end_mcsecond - $start_mcsecond ) / ( 1000 * 1000 )));
}


# 检查 ssh 延时, 尝试链接服务器 22 端口，并且读取一个字节
# 返回 2 个值，($ok,$time), $ok 表示是否链接成功，$time 表示链接耗时
sub check_ssh {
    my $sock = IO::Socket::INET->new(
        Proto    => "tcp",
        PeerAddr => $_[0],
        PeerPort => 22,
    );
    my ( $ssh_start_sec, $ssh_start_mcsecond ) = gettimeofday();
    my $len                                    = 1;
    my $buf;
    if(!defined($sock)){
        return "TIMEOUT";
    }
    $sock->sysread($buf,$len);
    my ($ssh_end_sec, $ssh_end_mcsecond ) = gettimeofday();
    my $ssh_time                          = ($ssh_end_sec - $ssh_start_sec) + ($ssh_end_mcsecond - $ssh_start_mcsecond) / (1000*1000);
    return sprintf("%2.2fs",$ssh_time);
}

my $github         = github_ip();
print("done\n");
my @web_ip         = @{$github->web};
my @git_ip         = @{$github->git};
my $count :shared;
$count             = $#web_ip + $#git_ip;
foreach my $ip (@web_ip) {
    threads->new(sub{
        my $host          = $_[0];
        my $http_duration = check_http($host);
        printf "%-20s%-10s%-10s\n",$host,$http_duration,"HTTPS";
        {
            lock($count);
            $count = $count -1
        }
    },$ip)->detach();
}
foreach my $ip (@git_ip) {
    threads->new(sub{
        my $host         = $_[0];
        my $ssh_duration = check_ssh($host);
        printf "%-20s%-10s%-10s\n",$host,$ssh_duration, "SSH";
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
