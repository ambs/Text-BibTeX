# -*- cperl -*-
use strict;
use warnings;

use Capture::Tiny 'capture';
use IO::Handle;
use Test::More tests => 32;

use vars qw($DEBUG);

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
$entry = new Text::BibTeX::Entry $bibfile;

ok($entry->read ($bibfile));
