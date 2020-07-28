#!/bin/perl
my @files = glob "/home/hellojukay/Desktop/*";
foreach $file (@files) {
    my $modify_date = -M $file;
    if ($modify_date < 1.0) {
        next if ($file =~ /delete/);
        printf "%s\n", $file;
        system "rm -rf $file";
    }
}
