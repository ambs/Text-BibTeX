package MyBuilder;
use base 'Module::Build';

use warnings;
use strict;

use Config::AutoConf;
use Config::AutoConf::Linker;

sub process_progs_files {
    my $builder = shift;
    my $cbuilder = $builder->cbuilder;

    my $EXEEXT = $Config::AutoConf::EXEEXT;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    for my $file (qw'dumpnames biblex bibparse args getopt getopt1') {
        $cbuilder->compile(object_file  => "btparse/progs/$file.o",
                           include_dirs => ["btparse/src"],
                           source       => "btparse/progs/$file.c");
    }

    print STDERR "\n** Creating dumpnames$EXEEXT **\n";
    # NO INST?
    $CCL->($cbuilder,
           exe_file => "btparse/progs/dumpnames$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ "btparse/progs/dumpnames.o" ]);

    print STDERR "\n** Creating biblex$EXEEXT **\n";
    # NO INST?
    $CCL->($cbuilder,
           exe_file => "btparse/progs/biblex$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ "btparse/progs/biblex.o" ]);


    print STDERR "\n** Creating bibparse$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/progs/bibparse$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map {"btparse/progs/$_.o"} (qw.bibparse args getopt getopt1.) ]);

    $builder->copy_if_modified( from    => "btparse/progs/dumpnames$EXEEXT",
                                to_dir  => "blib/bin",
                                flatten => 1);
    $builder->copy_if_modified( from    => "btparse/progs/biblex$EXEEXT",
                                to_dir  => "blib/bin",
                                flatten => 1);
    $builder->copy_if_modified( from    => "btparse/progs/bibparse$EXEEXT",
                                to_dir  => "blib/bin",
                                flatten => 1);
}


sub process_ctests_files {
    my $builder = shift;
    my $cbuilder = $builder->cbuilder;

    my $EXEEXT = $Config::AutoConf::EXEEXT;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    for my $file (qw'simple_test testlib read_test postprocess_test
                     macro_test name_test purify_test') {
        $cbuilder->compile(object_file => "btparse/tests/$file.o",
                           source      => "btparse/tests/$file.c");
    }

    print STDERR "\n** Creating simple_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/simple_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.simple_test testlib.) ]);

    print STDERR "\n** Creating read_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/read_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.read_test testlib.) ]);

    print STDERR "\n** Creating postprocess_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/postprocess_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.postprocess_test.) ]);

    print STDERR "\n** Creating macro_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/macro_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.macro_test.) ]);

    print STDERR "\n** Creating name_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/name_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.name_test.) ]);

    print STDERR "\n** Creating purify_test$EXEEXT **\n";
    $CCL->($cbuilder,
           exe_file => "btparse/tests/pufiry_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.purify_test.) ]);


}

sub process_mans_files {
    my $builder = shift;
    my @pods = glob("btparse/doc/*.pod");
    mkdir "blib/bindoc" unless -d "blib/bindoc";
    my $version = $builder->notes('btparse_version');
    for my $pod (@pods) {
        my $man = $pod;
        $man =~ s!.pod!.1!;
        $man =~ s!btparse/doc!blib/bindoc!;
        `pod2man --section=1 --center="btparse" --release="btparse, version $version" $pod $man`;
    }
}

sub process_libbtparse_files {
    my $builder = shift;
    my $cbuilder = $builder->cbuilder;

    my $LIBEXT = $Config::AutoConf::LIBEXT;
    print STDERR "\n** Creating libbtparse$LIBEXT **\n";

    my @modules = qw:init input bibtex err scan error
                     lex_auxiliary parse_auxiliary bibtex_ast sym
                     util postprocess macros traversal modify
                     names tex_tree string_util format_name:;

    for my $file (@modules) {
        $cbuilder->compile(object_file => "btparse/src/$file.o",
                           source      => "btparse/src/$file.c");
    }

    my @objects = map { "btparse/src/$_.o" } @modules;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    $LD->($cbuilder,
          module_name => 'btparse',
          objects => \@objects,
          lib_file => "btparse/src/libbtparse$LIBEXT");

}

1;
