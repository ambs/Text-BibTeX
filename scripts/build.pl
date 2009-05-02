#!/usr/bin/perl

use warnings;
use strict;

use File::Copy;
use Config::AutoConf;
use ExtUtils::CBuilder;

my $VERSION = get_version();
# Show some information to the user about what are we doing.
print "\n - Building btparse ($VERSION) - \n";

print "Checking for a working C compiler...";
if (not Config::AutoConf->check_cc()) {
	die "I need a C compiler. Please install one!\n" 
} else {
	print " [found]\n"
}

print "Checking for a make command...";
my $make = Config::AutoConf->check_progs("make","dmake","nmake");
if (!$make) {
	die "I need a make program. Please install one!\n"
} else {
	print " [found]\n"
}

## Build PODs
print "Building manpages...\n";
my @pods = <btparse/doc/*.pod>;
for my $pod (@pods) {
    my $man = $pod;
    $man =~ s!pod$!3!;
    print " - $pod to $man\n";
    `pod2man --section=3 --center="btparse" --release="btparse, version $VERSION" $pod $man`;
    move($man, 'blib/man3/');
}

my $CC = ExtUtils::CBuilder->new(quiet => 0);



sub get_version {
    my $version = undef;
    open PM, "BibTeX.pm" or die "Cannot open file [BibTeX.pm] for reading\n";
    while(<PM>) {
        if (m!^our\s+\$VERSION\s*=\s*'([^']+)'!) {
            $version = $1;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on your .pm file. Weirdo!\n" unless $version;
}
