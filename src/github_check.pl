#!/bin/perl
# 从 github 的 api 接口获取所有的 github ip 地址
# github api 参考文档地址: https://docs.github.com/cn/rest/reference/meta
# curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/meta

use warnings;
use strict;

use LWP::UserAgent;
use JSON;
use Time::HiRes qw(gettimeofday);
use Net::Ping;


# 返回 github 的所有 ip 地址
sub request_github {
    my $ua           = LWP::UserAgent->new(Agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36');
    my $req          = HTTP::Request->new(GET => 'https://api.github.com/meta');
    $req->header(Accept => "application/vnd.github.v3+json");
    my $res          = $ua->request($req);
    unless($res->is_success) {
        print $res->status_line, "\n";
   } 
    my $content      = $res->content;
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
    printf "%-18s %2.2fs \n",$ip , $duraiton;
}
my @ips = request_github();
foreach my $ip (@ips) {
    check_icmp($ip);
}

