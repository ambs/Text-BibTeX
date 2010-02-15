# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 22;

BEGIN {
    use_ok('Text::BibTeX');
    require "t/common.pl";
}

setup_stderr;

# ----------------------------------------------------------------------
# entry modification methods

my ($text, $entry, @warnings, @fieldlist);

$text = <<'TEXT';
@article{homer97,
  author = {Homer Simpson and Ned Flanders},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

ok($entry = new Text::BibTeX::Entry);
ok($entry->parse_s ($text));

ok($entry->type eq 'article');
$entry->set_type ('book');
ok($entry->type eq 'book');

ok($entry->key eq 'homer97');
$entry->set_key ($entry->key . 'a');
ok($entry->key eq 'homer97a');

my @names = $entry->names ('author');
$names[0] = $names[0]->{'last'}[0] . ', ' . $names[0]->{'first'}[0];
$names[1] = $names[1]->{'last'}[0] . ', ' . $names[1]->{'first'}[0];
$entry->set ('author', join (' and ', @names));

my $author = $entry->get ('author');
ok($author eq 'Simpson, Homer and Flanders, Ned');
ok(! warnings);

$entry->set (author => 'Foo Bar {and} Co.', 
             title  => 'This is a new title');
ok($entry->get ('author') eq 'Foo Bar {and} Co.');
ok($entry->get ('title') eq 'This is a new title');
ok(slist_equal ([$entry->get ('author', 'title')],
                   ['Foo Bar {and} Co.', 'This is a new title']));
ok(! warnings);

ok(slist_equal ([$entry->fieldlist], [qw(author title journal year)]));
ok($entry->exists ('journal'));

$entry->delete ('journal');
@fieldlist = $entry->fieldlist;
ok(! $entry->exists ('journal') &&
      slist_equal (\@fieldlist, [qw(author title year)]));
ok(! warnings);

$entry->set_fieldlist ([qw(author title journal year)]);
@warnings = warnings;
ok(@warnings == 1 && 
      $warnings[0] =~ /implicitly adding undefined field \"journal\"/i);

@fieldlist = $entry->fieldlist;
ok($entry->exists ('journal') &&
      ! defined $entry->get ('journal') &&
      slist_equal (\@fieldlist, [qw(author title journal year)]));
ok(! warnings);

$entry->delete ('journal', 'author', 'year');
@fieldlist = $entry->fieldlist;
ok(! $entry->exists ('journal') &&
      ! $entry->exists ('author') &&
      ! $entry->exists ('year') &&
      @fieldlist == 1 && $fieldlist[0] eq 'title');
ok(! warnings);
