#-*- cperl -*-

use strict;
use warnings;

use Test::More tests => 1;

use File::Copy;
use File::Spec::Functions;

if ($^O !~ /mswin32/i) {
    ok 1
} else {
    my $windir = $ENV{WINDIR};

    my $backup = catfile("t","libbtparse.dll");
    if (-f $backup) {
        my $installed_libbtparse = catfile($windir, "libbtparse.dll");
        move($backup, $installed_libbtparse);
    }
    ok 1;
}
