#!/bin/perl
my @files = glob "/home/hellojukay/Desktop/*";
foreach $file (@files) {
    # -M 返回文件修改距离现在的时间距离，单位是：天
    my $modify_date = -M $file;
    if ($modify_date < 1.0) {
        next if ($file =~ /delete/);
        printf "%s\n", $file;
        system "rm -rf $file";
    }
}
