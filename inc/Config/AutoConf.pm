package inc::Config::AutoConf;
use ExtUtils::CBuilder;
use 5.008002;

use Config;

use File::Temp qw/tempfile/;
use File::Spec;

use base 'Exporter';

our @EXPORT = ('$LIBEXT', '$EXEEXT');

use warnings;
use strict;

our $LIBEXT = ($^O =~ /darwin/i)  ? ".dylib" : ( ($^O =~ /mswin32/i) ? ".dll" : ".so" );
our $EXEEXT = ($^O =~ /mswin32/i) ? ".exe" : "";

=head1 NAME

Config::AutoConf - A module to implement some of AutoConf macros in pure perl.

=cut

our $VERSION = '0.15';

=head1 ABSTRACT

With this module I pretend to simulate some of the tasks AutoConf
macros do. To detect a command, to detect a library, etc.

=head1 SYNOPSIS

    use Config::AutoConf;

    Config::AutoConf->check_prog("agrep");
    my $grep = Config::AutoConf->check_progs("agrep", "egrep", "grep");

    Config::AutoConf->check_header("ncurses.h");
    my $curses = Config::AutoConf->check_headers("ncurses.h","curses.h");

    Config::AutoConf->check_prog_awk;
    Config::AutoConf->check_prog_egrep;

    Config::AutoConf->check_cc();

    Config::AutoConf->check_lib("ncurses", "tgoto");

    Config::AutoConf->check_file("/etc/passwd"); # -f && -r

=head1 FUNCTIONS

=head2 check_file

This function checks if a file exists in the system and is readable by
the user. Returns a boolean. You can use '-f $file && -r $file' so you
don't need to use a function call.

=cut

sub check_file {
  my $class = shift;
  my $file = shift;

  return (-f $file && -r $file);
}


=head2 check_files

This function checks if a set of files exist in the system and are
readable by the user. Returns a boolean.

=cut

sub check_files {
  my $class = shift;

  for (@_) {
    return 0 unless check_file($class, $_)
  }

  return 1;
}


=head2 check_prog

This function checks for a program with the supplied name. In success
returns the full path for the executable;

=cut

sub check_prog {
  my $class = shift;
  # sanitize ac_prog
  my $ac_prog = _sanitize(shift());
  my $PATH = $ENV{PATH};
  my $p;

	my $ext = "";
	$ext = ".exe" if $^O =~ /mswin/i;
	
  for $p (split /$Config{path_sep}/,$PATH) {
    my $cmd = File::Spec->catfile($p,$ac_prog.$ext);
    return $cmd if -x $cmd;
  }
  return undef;
}

=head2 check_progs

This function takes a list of program names. Returns the full path for
the first found on the system. Returns undef if none was found.

=cut

sub check_progs {
  my $class = shift;
  my @progs = @_;
  for (@progs) {
    my $ans = check_prog($class, $_);
    return $ans if $ans;
  }
  return undef;
}

=head2 check_prog_yacc

From the autoconf documentation,

  If `bison' is found, set [...] `bison -y'.
  Otherwise, if `byacc' is found, set [...] `byacc'. 
  Otherwise set [...] `yacc'.

Returns the full path, if found.

=cut

sub check_prog_yacc {
	my $class = shift;
	my $binary = check_progs(qw/$class bison byacc yacc/);
	$binary .= " -y" if ($binary =~ /bison$/);
	return $binary;
}

=head2 check_prog_awk

From the autoconf documentation,

  Check for `gawk', `mawk', `nawk', and `awk', in that order, and
  set output [...] to the first one that is found.  It tries
  `gawk' first because that is reported to be the best
  implementation.

Note that it returns the full path, if found.

=cut

sub check_prog_awk {
  my $class = shift;
  return check_progs(qw/$class gawk mawk nawk awk/);
}


=head2 check_prog_egrep

From the autoconf documentation,

  Check for `grep -E' and `egrep', in that order, and [...] output
  [...] the first one that is found.

Note that it returns the full path, if found.

=cut

sub check_prog_egrep {
  my $class = shift;

  my $grep;

  if ($grep = check_prog($class,"grep")) {
    my $ans = `echo a | ($grep -E '(a|b)') 2>/dev/null`;
    return "$grep -E" if $ans eq "a\n";
  }

  if ($grep = check_prog($class, "egrep")) {
    return $grep;
  }
  return undef;
}

=head2 check_cc

This function checks if you have a running C compiler.

=cut

sub check_cc {
  ExtUtils::CBuilder->new(quiet => 1)->have_compiler;
}

=head2 check_headers

This function uses check_header to check if a set of include files exist in the system and can
be included and compiled by the available compiler. Returns the name of the first header file found.

=cut

sub check_headers {
  my $class = shift;

  for (@_) {
    return $_ if check_header($class, $_)
  }

  return undef;
}


=head2 check_header

This function is used to check if a specific header file is present in
the system: if we detect it and if we can compile anything with that
header included. Note that normally you want to check for a header
first, and then check for the corresponding library (not all at once).

The standard usage for this module is:

  Config::AutoConf->check_header("ncurses.h");
  
This function will return a true value (1) on success, and a false value
if the header is not present or not available for common usage.

=cut

sub check_header {
    my $class = shift;
    my $header = shift;
    
    my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);
    
    return 0 unless $header;
    
    # print STDERR "Trying to compile a test program to check [$header] availability...\n";
    
    my $conftest = <<"_ACEOF";
    /* Override any gcc2 internal prototype to avoid an error.  */
    #ifdef __cplusplus
    extern "C"
    #endif

    #include <$header>

    int
    main ()
    {
      return 0;
    }    
_ACEOF

    my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c');
    $filename =~ m!^(.*).c$!;
    my $base = $1;

    print {$fh} $conftest;
    close $fh;

    my $obj_file = eval{ $cbuilder->compile(source => $filename) };

    if ($@ || !$obj_file) {
        unlink $filename;
        unlink $obj_file if $obj_file;        
        return 0         
    }

    my $exe_file = eval { $cbuilder->link_executable(objects => $obj_file) };

    unlink $filename;
    unlink $obj_file if $obj_file;
    unlink $exe_file if $exe_file;

    return 0 if $@;
    return 0 unless $exe_file;

    return 1;
}

=head2 check_lib

This function is used to check if a specific library includes some
function. Call it with the library name (without the lib portion), and
the name of the function you want to test:

  Config::AutoConf->check_lib("z", "gzopen");

It returns 1 if the function exist, 0 otherwise.

=cut

sub check_lib {
  my $class = shift;
  my $lib = shift;
  my $func = shift;

  my $cbuilder = ExtUtils::CBuilder->new(quiet => 1);

  return 0 unless $lib;
  return 0 unless $func;

  # print STDERR "Trying to compile test program to check [$func] on [$lib] library...\n";

  my $LIBS = "-l$lib";
  my $conftest = <<"_ACEOF";
/* Override any gcc2 internal prototype to avoid an error.  */
#ifdef __cplusplus
extern "C"
#endif
/* We use char because int might match the return type of a gcc2
   builtin and then its argument prototype would still apply.  */
char $func ();
int
main ()
{
  $func ();
  return 0;
}
_ACEOF



  my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c');
  $filename =~ m!(.*).c$!;
  my $base = $1;

  print {$fh} $conftest;
  close $fh;

  my $obj_file = eval{ $cbuilder->compile(source => $filename) };

  if ($@ || !$obj_file) {
      unlink $filename;
      unlink $obj_file if $obj_file;        
      return 0         
  }

  my $exe_file = eval { $cbuilder->link_executable(objects => $obj_file,
						   extra_linker_flags => $LIBS) };

  unlink $filename;
  unlink $obj_file if $obj_file;
  unlink $exe_file if $exe_file;

  return 0 if $@;
  return 0 unless $exe_file;

  return 1;
}

#
#
# Auxiliary funcs
#

sub _sanitize {
  # This is hard coded, and maybe a little stupid...
  my $x = shift;
  $x =~ s/ //g;
  $x =~ s/\///g;
  $x =~ s/\\//g;
  return $x;
}


=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

=head1 NEXT STEPS

Although a lot of work needs to be done, this is the next steps I
intent to take.

  - detect flex/lex
  - detect yacc/bison/byacc
  - detect ranlib (not sure about its importance)

These are the ones I think not too much important, and will be
addressed later, or by request.

  - detect an 'install' command
  - detect a 'ln -s' command -- there should be a module doing
    this kind of task.

=head1 BUGS

A lot. Portability is a pain. B<<Patches welcome!>>.

Please report any bugs or feature requests to
C<bug-extutils-autoconf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Michael Schwern for kind MacOS X help.

Ken Williams for ExtUtils::CBuilder

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Alberto Simões, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

ExtUtils::CBuilder(3)

=cut

1; # End of Config::AutoConf
