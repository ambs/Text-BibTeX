#!/usr/bin/perl

use warnings;
use strict;

use File::Copy;
use Config::AutoConf;
use ExtUtils::CBuilder;

my $VERSION = get_version();
my $EXE = "";
$EXE = ".exe" if $^O eq "MSWin32";
my $LIBEXT = ".so";
$LIBEXT = ".bundle" if $^O =~ /darwin/i;
$LIBEXT = ".dll"   if $^O =~ /mswin32/i;

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
print "\nBuilding manpages...\n";
my @pods = <btparse/doc/*.pod>;
for my $pod (@pods) {
    my $man = $pod;
    $man =~ s!pod$!3!;
    print " - $pod to $man\n";
    `pod2man --section=3 --center="btparse" --release="btparse, version $VERSION" $pod $man`;
    move($man, 'blib/man3/');
}

## Build libbtparse
print "\nCompiling libbtparse...\n";
my $CC = ExtUtils::CBuilder->new(quiet => 0);

my @sources = qw:init.c input.c bibtex.c err.c scan.c error.c
                 lex_auxiliary.c parse_auxiliary.c bibtex_ast.c sym.c
                 util.c postprocess.c macros.c traversal.c modify.c
                 names.c tex_tree.c string_util.c format_name.c:;

my @objects = map {
    $CC->compile(include_dirs => ['btparse/pccts'],
                 source => "btparse/src/$_" )
} @sources;

$CC->link(module_name => 'btparse',
          objects => \@objects,
          lib_file => "btparse/src/libbtparse$LIBEXT");

## Build dumpnames
print "\nCompiling dumpnames application...\n";
@sources = qw!dumpnames.c!;
@objects =  map {
    $CC->compile(include_dirs => ['btparse/src'],
                 source => "btparse/progs/$_" )
} @sources;
$CC->link_executable(exe_file => "btparse/progs/dumpnames$EXE",
                     objects => ["btparse/src/libbtparse$LIBEXT",@objects]);

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
