package inc::Config::AutoConf::Linker;
use ExtUtils::CBuilder;
use 5.008002;

use warnings;
use strict;

use inc::Config::AutoConf;

use File::Spec;
use File::Temp qw/tempdir/;

sub detect_library_link_commands {
    my $CCOMP = shift;
    my $dir = tempdir(CLEANUP => 1);
    _write_files($dir);

    my $quiet_state = $CCOMP->{quiet};
    $CCOMP->{quiet} = 1;

    my $CREATE_LIB;
    my $LINK_WITH_LIB;

    ## Handle Mac should be just this [HACK! HACK!]
    $CCOMP->{config}{lddlflags} =~ s/-bundle/-dynamiclib/;

    ## Now, try to compile it directly using EU::CB
    my @source_files = map { File::Spec->catfile($dir,$_) } ('library.c', 'test.c');

    ## Create object files
    my @objects = map { $CCOMP->compile(source => $_); } @source_files;

    ## Calculate filenames
    my $libfile = File::Spec->catfile($dir, "libfoo$LIBEXT");
    my $exefile = File::Spec->catfile($dir, "foo$EXEEXT");

    $CCOMP->link( objects     => [$objects[0]],
                  module_name => "foo",
                  lib_file    => $libfile );

    if (-f $libfile) {
        $CREATE_LIB = sub {
            my $CC = shift;
            $CC->{config}{lddlflags} =~ s/-bundle/-dynamiclib/;
            return $CC->link(@_);
        };

        $CCOMP->link_executable(exe_file => $exefile,
                                extra_linker_flags => "-L$dir -lfoo",
                                objects => [$objects[1]]);
        if (-f $exefile && -x _ ) {
            $LINK_WITH_LIB = sub {
                my $CC = shift;
                return $CC->link_executable(@_);
            }
        }
        else {
            $LINK_WITH_LIB = undef;
        }
    } else {
	my $LD = $CCOMP->{config}{ld};

        system($LD,"-shared","-o",$libfile,$objects[0]);
	if (-f $libfile) {
            $CREATE_LIB = sub {
                my $CC = shift;
                my %conf = @_;
                system($LD,"-shared","-o",$conf{lib_file},@{$conf{objects}});
            };

            system($LD, "-o",$exefile,"-L$dir", "-lfoo", $objects[1]);
            if (-f $exefile && -x _) {
                $LINK_WITH_LIB = sub {
                    my $CC = shift;
                    my %conf = @_;
                    my @CFLAGS = split /\s+/, $conf{extra_linker_flags};
                    system($LD,"-o",$conf{exe_file},@CFLAGS,@{$conf{objects}});
                }
            } else {
                $LINK_WITH_LIB = undef;
            }
	} else {
            $CREATE_LIB = undef;
            $LINK_WITH_LIB = undef;
	}
    }

    $CCOMP->{quiet} = $quiet_state;

    return ($CREATE_LIB, $LINK_WITH_LIB);
}


sub _write_files {
    my $fh;
    my $outpath = shift;

    seek DATA, 0, 0;
    while(<DATA>) {
        if (m!^==\[(.*?)\]==!) {
	    my $fname = $1;
            $fname = File::Spec->catfile($outpath, $fname);
            open $fh, ">$fname" or die "Can't create temporary file $fname\n";
        } elsif ($fh) {
            print $fh $_;
        }
    }
}

1;

=head1 NAME

Config-AutoConf-Linker - Utilities to detect how to link a library

=head1 SYNOPSIS

  use Config::AutoConf::Linker;
  use ExtUtils::CBuilder;

  my $CC = ExtUtils::CBuilder->new(quiet => 0);
  my ($library_linker, $link_with_lib) = Config::AutoConf::Linker::detect_library_link_commands($CC);

=head1 DESCRIPTION

=head2 detect_library_link_commands

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alberto Manuel Brandão Simões

=cut


__DATA__
==[library.c]==
  int answer(void) {
      return 42;
  }
==[test.c]==
#include <stdio.h>

int main() {
    int a = answer();
    printf("%d\n", a);
    return 0;
}

