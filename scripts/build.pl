#!/usr/bin/perl

use warnings;
use strict;

use Config::AutoConf;
use ExtUtils::CBuilder;

# Show some information to the user about what are we doing.
print "\n - Building btparse - \n";

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
