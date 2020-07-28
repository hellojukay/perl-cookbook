use strict;
use warnings;
# 依赖 ss 
# ss 命令来自 iproute2 包
# https://blog.hellojukay.cn/2019/09/11/20190912/
my @lines = `ss -atp`;
my %hash;
for my $line (@lines) {
    if($line =~ /pid=(\d{1,9})/) {
        $hash{$1}++;
    }
}
printf "%s %10s   %s\n", "pid","tcp_count","cmdline";
for my $pid (keys %hash) {
    my $cmd = `cat /proc/$pid/cmdline`;
    printf "%5d %5d     %s\n", $pid,$hash{$pid},$cmd;
}
