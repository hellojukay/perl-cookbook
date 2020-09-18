#!/usr/bin/perl
use strict;
use warnings;
 
use IO::Handle;
 
my $max_len = 0;
sub render($) {
    if($_[0] > $max_len) {
        # 加上后面的两个数字和百分号
        $max_len = $_[0] + 3;
    }
    clean();
    my $content =  "#" x $_[0];
    print $content . $_[0] . "%";
    STDOUT->flush();
}
sub clean() {
    my $str = sprintf "\r%s\r", " " x $max_len;
    print $str;
    STDOUT->flush();
}
 
while(1) {
    my $progress = int(rand(100));
    render($progress);
    sleep 1;
}
