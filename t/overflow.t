# -*- cperl -*-
use strict;
use warnings;

use Capture::Tiny 'capture';
use IO::Handle;
use Test::More tests => 3;

use vars qw($DEBUG);
use YAML; print Dump(\%ENV);
BEGIN {
    use_ok('Text::BibTeX');
    require "t/common.pl";
}

$DEBUG = 0;


# ----------------------------------------------------------------------
# entry creation and parsing from a Text::BibTeX::File object

my ($bibfile, $entry);
my $multiple_file = 'btparse/tests/data/overflow.bib';

ok($bibfile = new Text::BibTeX::File $multiple_file);
# this used to trigger a buffer overflow error on some machines
$entry = new Text::BibTeX::Entry $bibfile;
ok(1,"not segfaulted"); # not segfaulted here
