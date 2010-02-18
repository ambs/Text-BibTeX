package MyBuilder;
use base 'Module::Build';

use warnings;
use strict;

use Config;
use Carp;

use Config::AutoConf;
use Config::AutoConf::Linker;

use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;

use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;

sub ACTION_code {
    my $self = shift;

    for my $path (catdir("blib","bindoc"), catdir("blib","bin")) {
        mkpath $path unless -d $path;
    }

    $self->dispatch("create_manpages");
    $self->dispatch("create_objects");
    $self->dispatch("create_library");
    $self->dispatch("create_binaries");
    $self->dispatch("create_tests");

    $self->dispatch("compile_xscode");

    $self->SUPER::ACTION_code;
}

sub ACTION_compile_xscode {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $archdir = catdir( $self->blib, 'arch', 'auto', 'Text', 'BibTeX');
    mkpath( $archdir, 0, 0777 ) unless -d $archdir;

    print STDERR "\n** Preparing XS code\n";
    my $cfile = catfile("xscode","BibTeX.c");
    my $xsfile= catfile("xscode","BibTeX.xs");

    $self->add_to_cleanup($cfile); ## FIXME
    if (!$self->up_to_date($xsfile, $cfile)) {
        ExtUtils::ParseXS::process_file( filename   => $xsfile,
                                         prototypes => 0,
                                         output     => $cfile);
    }

    my $ofile = catfile("xscode","BibTeX.o");
    $self->add_to_cleanup($ofile); ## FIXME
    if (!$self->up_to_date($cfile, $ofile)) {
        $cbuilder->compile( source               => $cfile,
                            include_dirs         => [ catdir("btparse","src") ],
                            object_file          => $ofile);
    }

    # Create .bs bootstrap file, needed by Dynaloader.
    my $bs_file = catfile( $archdir, "BibTeX.bs" );
    if ( !$self->up_to_date( $ofile, $bs_file ) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if ( !-f $bs_file ) {
            # Create file in case Mkbootstrap didn't do anything.
            open( my $fh, '>', $bs_file ) or confess "Can't open $bs_file: $!";
        }
        utime( (time) x 2, $bs_file );    # touch
    }

    my $objects = $self->rscan_dir("xscode",qr/\.o$/);
    # .o => .(a|bundle)
    my $lib_file = catfile( $archdir, "BibTeX.$Config{dlext}" );
    if ( !$self->up_to_date( [ @$objects ], $lib_file ) ) {
        $cbuilder->link(
                        module_name => 'Text::BibTeX',
                        extra_linker_flags => '-Lbtparse/src -lbtparse ',
                        objects     => $objects,
                        lib_file    => $lib_file,
                       );
    }
}

sub ACTION_create_manpages {
    my $self = shift;

    print STDERR "\n** Creating Manpages\n";

    my $pods = $self->rscan_dir(catdir("btparse","doc"), qr/\.pod$/);

    my $version = $self->notes('btparse_version');
    for my $pod (@$pods) {
        my $man = $pod;
        $man =~ s!.pod!.1!;
        $man =~ s!btparse/doc!blib/bindoc!;   ## FIXME - path
        next if $self->up_to_date($pod, $man);
        ## FIXME
        `pod2man --section=1 --center="btparse" --release="btparse, version $version" $pod $man`;
    }

    my $pod = 'btool_faq.pod';
    my $man = catfile('blib','bindoc','btool_faq.1');
    unless ($self->up_to_date($pod, $man)) {
        ## FIXME
        `pod2man --section=1 --center="btparse" --release="btparse, version $version" $pod $man`;
    }
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    print STDERR "\n** Compiling C files\n";
    my $c_progs = $self->rscan_dir('btparse/progs', qr/\.c$/);
    my $c_src   = $self->rscan_dir('btparse/src',   qr/\.c$/);
    my $c_tests = $self->rscan_dir('btparse/tests', qr/\.c$/);
    my $c_xs    = $self->rscan_dir('xscode/',       qr/\.c$/);

    my @c_files = (@$c_progs, @$c_src, @$c_tests, @$c_xs);
    for my $file (@c_files) {
        my $object = $file;
        $object =~ s/\.c/.o/;
        next if $self->up_to_date($file, $object);
        $cbuilder->compile(object_file  => $object,
                           source       => $file,
                           include_dirs => ["btparse/src"]);
    }
}


sub ACTION_create_binaries {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $EXEEXT = $Config::AutoConf::EXEEXT;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    print STDERR "\n** Creating binaries (dumpnames$EXEEXT, biblex$EXEEXT, bibparse$EXEEXT)\n";

    # NO INST?
    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/progs/dumpnames$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ "btparse/progs/dumpnames.o" ]);

    # NO INST?
    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/progs/biblex$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ "btparse/progs/biblex.o" ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/progs/bibparse$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map {"btparse/progs/$_.o"} (qw.bibparse args getopt getopt1.) ]);

    $self->copy_if_modified( from    => "btparse/progs/dumpnames$EXEEXT",
                             to_dir  => "blib/bin",
                             flatten => 1);
    $self->copy_if_modified( from    => "btparse/progs/biblex$EXEEXT",
                             to_dir  => "blib/bin",
                             flatten => 1);
    $self->copy_if_modified( from    => "btparse/progs/bibparse$EXEEXT",
                             to_dir  => "blib/bin",
                             flatten => 1);
}

sub ACTION_create_tests {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $EXEEXT = $Config::AutoConf::EXEEXT;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    print STDERR "\n** Creating test binaries\n";

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/simple_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.simple_test testlib.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/read_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.read_test testlib.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/postprocess_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.postprocess_test.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/tex_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.tex_test.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/macro_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.macro_test.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/name_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.name_test.) ]);

    ## FIXME - uptodate
    $CCL->($cbuilder,
           exe_file => "btparse/tests/pufiry_test$EXEEXT",
           extra_linker_flags => '-Lbtparse/src -lbtparse ',
           objects => [ map "btparse/tests/$_.o", (qw.purify_test.) ]);
}

sub ACTION_create_library {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $LIBEXT = $Config::AutoConf::LIBEXT;
    print STDERR "\n** Creating libbtparse$LIBEXT\n";

    my @modules = qw:init input bibtex err scan error
                     lex_auxiliary parse_auxiliary bibtex_ast sym
                     util postprocess macros traversal modify
                     names tex_tree string_util format_name:;

    my @objects = map { "btparse/src/$_.o" } @modules;

    my ($LD,$CCL) = Config::AutoConf::Linker::detect_library_link_commands($cbuilder);
    die "Can't get a suitable way to compile a C library\n" if (!$LD || !$CCL);

    my $libfile = "btparse/src/libbtparse$LIBEXT";
    $LD->($cbuilder,
          module_name => 'btparse',
          objects => \@objects,
          lib_file => $libfile);

    my $libdir = catdir($self->blib, 'usrlib');
    mkpath( $libdir, 0, 0777 ) unless -d $libdir;

    $self->copy_if_modified( from   => $libfile,
                             to_dir => $libdir,
                             flatten => 1 );
}

sub ACTION_test {
    my $self = shift;

    if ($^O =~ /darwin/i) {
        $ENV{DYLD_LIBRARY_PATH} = catdir($self->blib,"usrlib").":$ENV{DYLD_LIBRARY_PATH}";
    }
    if ($^O =~ /linux/i) {
        $ENV{LD_LIBRARY_PATH} = catdir($self->blib,"usrlib").":$ENV{LD_LIBRARY_PATH}";
    }

    $self->SUPER::ACTION_test
}

1;
