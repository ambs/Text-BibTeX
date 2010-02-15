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

    my $installed_libbtparse = catfile($windir, "libbtparse.dll");

    if (-f $installed_libbtparse) {
        move($installed_libbtparse, "t");
    }
    copy(catfile("blib","usrlib","libbtparse.dll"), $installed_libbtparse);

    ok 1;
}
