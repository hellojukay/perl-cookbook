#!/usr/bin/perl
use strict;
use warnings;

my @files = @ARGV;
unless(@files){
    exit 0;
}

sub rm_dir{
    my $dir = $_[0];
    return unless (-e $dir);
    opendir DH, $dir or print "can not open dir $dir , $!\n";
    my @files = readdir DH;
    foreach my $file (@files) {
        next if($file =~ /^\.$|^\.\.$/);
        $file = join "/",($dir,$file);
        if(-f $file) {
            unlink $file or print "can not remove file $file, $!\n";
        }else {
            rm_dir($file) unless(rmdir $file);
        }
    }
    rmdir $dir;
}
foreach my $file (@files) {
    next  unless(-e $file);
    if((-f $file) || (-l $file)) {
        unlink $file;
        next;
    }
    if(-d $file){
        rm_dir($file);
        next;
    }
}
