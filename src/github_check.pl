#!/bin/perl
# 从 github 的 api 接口获取所有的 github ip 地址
# github api 参考文档地址: https://docs.github.com/cn/rest/reference/meta
# curl -H "Accept: application/vnd.github.v3+json"  https://api.github.com/meta

use warnings;
use strict;

use HTTP::Tiny;
use JSON;

# 返回 github 的所有 ip 地址
sub github_ips {
    my $response = HTTP::Tiny->new->get('https://api.github.com/meta',{headers => {'Accept' => 'plication/vnd.github.v3+json"'}});
    if($response->{status} != 200){
        die "github response code  $response->{status}";
    }

    my $content = $response->{content};
    my $json = JSON->new->allow_nonref;
    my $response_obj = $json->decode($content);
    return @{$response_obj->{git}};
}
my @ips = github_ips();
foreach my $ip (@ips) {
    print "$ip\n";
}

