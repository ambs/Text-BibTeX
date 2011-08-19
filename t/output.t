# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 16;

use vars qw($DEBUG);

BEGIN {
    use_ok('Text::BibTeX');
    require "t/common.pl";
}

use Fcntl;

# ----------------------------------------------------------------------
# entry output methods

my ($text, $entry, @warnings, @fields);
my ($new_text, $new_entry);

$text = <<'TEXT';
@article{homer97,
  author = "H{\"o}mer Simpson" # { \"und } # "Ned Flanders",
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT
ok($entry = new Text::BibTeX::Entry $text);
ok($entry->parse_ok);

$new_text = $entry->print_s;

like $new_text => qr/^\@article\{homer97,\s*$/m;
like $new_text => qr/^\s*author\s*=\s*{H{\\"o}mer Simpson \\"und Ned Flanders},\s*$/m;
like $new_text => qr/^\s*title\s*=\s*[{"]Territorial[^}"]*Suburbia[}"],\s*$/m;
like $new_text => qr/^\s*journal\s*=\s*[{"]Journal[^\}]*Studies[}"],\s*$/m;
like $new_text => qr/^\s*year\s*=\s*[{"]1997[}"],\s*$/m;

$new_entry = new Text::BibTeX::Entry $new_text;
ok($entry->parse_ok);

is $entry->type => $new_entry->type;
is $entry->key  => $new_entry->key;

ok(slist_equal (scalar $entry->fieldlist, scalar $new_entry->fieldlist));

@fields = $entry->fieldlist;
ok(slist_equal ([$entry->get (@fields)], [$new_entry->get (@fields)]));

my @test = map { "t/test$_.bib" } 1..3;
my ($bib);

END { unlink @test }

open (BIB, ">$test[0]") || die "couldn't create $test[0]: $!\n";
$entry->print (\*BIB);
close (BIB);

$bib = new IO::File $test[1], O_CREAT|O_WRONLY
   or die "couldn't create $test[1]: $!\n";
$entry->print ($bib);
$bib->close;

$bib = new Text::BibTeX::File $test[2], O_CREAT|O_WRONLY
   or die "couldn't create $test[2]: $!\n";
$entry->write ($bib);
$bib->close;

my (@contents, $i);
for $i (0 .. 2)
{
   open (BIB, $test[$i]) || die "couldn't open $test[$i]: $!\n";
   $contents[$i] = join ('', <BIB>);
   close (BIB);
}

is $new_text => $contents[0];
is $new_text => $contents[1];
is $new_text => $contents[2];

