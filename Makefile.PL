use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.008001;

# $Id$

my $EXE = "";
$EXE = ".exe" if $^O eq "MSWin32";

my $LIBEXT = ".so";
$LIBEXT = ".dylib"  if $^O =~ /darwin/i;
$LIBEXT = ".dll"    if $^O =~ /mswin32/i;

my @support_files = ( 'btxs_support$(OBJ_EXT)' );

my %conf =
  (
   'NAME'	    => 'Text::BibTeX',
   'VERSION_FROM'   => 'BibTeX.pm',
   'XSPROTOARG'     => '-prototypes',
   'INC'	    => '-Ibtparse/src',
   'MYEXTLIB'       => "btparse/src/libbtparse$LIBEXT",
#   'LIBS'           => '-lbtparse',
   'PREREQ_PM' => {
                   'File::Copy'         => '0',
                   'Config::AutoConf'   => '0.09',
                   'ExtUtils::CBuilder' => '0.23',
                  },
   'OBJECT'         => 'BibTeX$(OBJ_EXT) ' . join (' ', @support_files),
   'dynamic_lib'    => {
 #                       OTHERLDFLAGS => "-Lbtparse/src -lbtparse ",
                        INST_DYNAMIC_DEP => join (' ', @support_files) 
                       },
   'dist'           => { COMPRESS => "gzip", SUFFIX => "gz" },
   'clean'          => { FILES => "_dummy_" },
  );

WriteMakefile ( %conf );

#..........
package MY;

sub top_targets {
    my $inherited = shift->SUPER::top_targets(@_);
    $inherited =~ s!^(config\s*::.*)$!$1 btparse!m;
    $inherited;
}

sub install {
    my $inherited = shift->SUPER::install(@_);
    $inherited =~ s!install\s*::\s*all!install :: all installlib!;
    $inherited;
}

sub postamble {
    return <<"MAKE";

btparse: _dummy_
\t\$(NOECHO) \$(NOOP)

_dummy_: scripts/build.pl
\t\$(PERL) scripts/build.pl

btparse/src/libbtparse$LIBEXT: _dummy_

installlib: _dummy_
\t\$(CP) btparse/src/libbtparse$LIBEXT \$(SITEPREFIX)/lib

MAKE
}
