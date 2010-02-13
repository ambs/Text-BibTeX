use strict;
use warnings;

use lib 'inc';
use MyBuilder;

my $version = get_version();
interpolate("btparse/src/bt_config.h.in",
            "btparse/src/bt_config.h",
            PACKAGE => "\"libbtparse\"",
            FPACKAGE => "\"libbtparse $version\"",
            VERSION => "\"$version\"",
           );


my $builder = MyBuilder->new
  (
   module_name    => 'Text::BibTeX',
   license        => 'perl',
   dist_author    => ['Alberto Simões <ambs@cpan.org>',
                      'Greg Ward <gward@python.net>'],
#   c_source       => ['btparse/src', 'btparse/progs', 'btparse/tests'],
#   c_source       => ["BiBteX.c", "btxs_support.c"],
#   xs_files       => {'BibTeX.xs' => 'BibTeX.xs'},
   needs_compiler => 1,
   requires       => {
                      'File::Copy'         => '0',
                      'Config::AutoConf'   => '0.13',
                      'ExtUtils::CBuilder' => '0.27', # (0.28?)
                     },
   add_to_cleanup => [
                      'Text-BibTeX-*',
# NOT SURE YET        'btparse/src/bt_config.h',
                      'btparse/src/*.so',
                      'btparse/src/*.dylib',
                      'btparse/src/*.dll',
                      'btparse/src/*.o',
                      'btparse/progs/*.o',
                      'btparse/progs/dumpnames',
                      'btparse/progs/bibparse',
                      'btparse/progs/biblex',
                      'btparse/tests/postprocess_test',
                      'btparse/tests/read_test',
                      'btparse/tests/simple_test',
                      'btparse/tests/macro_test',
                      'btparse/tests/case_test',
                      'btparse/tests/name_test',
                      'btparse/tests/purify_test',
                     ],
  );

$builder->notes('btparse_version' => $version);
$builder->add_build_element('libbtparse');
$builder->add_build_element('progs');
#Later... $builder->add_build_element('ctests');
$builder->add_build_element('mans');

$builder->create_build_script;

sub get_version {
    my $version = undef;
    open PM, "lib/Text/BibTeX.pm" or die "Cannot open 'lib/Text/BibTeX.pm' for reading: $!\n";
    while (<PM>) {
        if (m!^our\s+\$VERSION\s*=\s*'([^']+)'!) {
            $version = $1;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on your .pm file. Weirdo!\n" unless $version;
}



sub interpolate {
    my ($from, $to, %config) = @_;
	
    print "Creating new '$to' from '$from'.\n";
    open FROM, $from or die "Cannot open file '$from' for reading.\n";
    open TO, ">", $to or die "Cannot open file '$to' for writing.\n";
    while (<FROM>) {
        s/\[%\s*(\S+)\s*%\]/$config{$1}/ge;		
        print TO;
    }
    close TO;
    close FROM;
}
