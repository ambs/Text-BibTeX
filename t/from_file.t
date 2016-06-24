use strict;
use warnings;

use Test::More tests => 5;
use utf8;

use Text::BibTeX;

my $bibtex = Text::BibTeX::File->new("t/corpora.bib", { ENCODING => 'utf-8'});
is ref($bibtex), "Text::BibTeX::File";

my @entries;
while (my $entry = Text::BibTeX::Entry->new($bibtex)) {
	push @entries, $entry;
}

is scalar(@entries), 25;

# @Article{linguamatica:6:2:Laboreiroetal,
#   author =       {Gustavo Laboreiro and Eugénio Oliveira},
#   title =        {Avaliação de métodos de desofuscação de palavrões},
#   journal =      {Linguamática},
#   year =         {2014},
#   volume =       {6},
#   number =       {2},
#   pages =        {25--43},
#   month =        {Dezembro},
#   editor =       {Alberto Simões and José João Almeida and Xavier Gómez Guinovart}
# }
is $entries[0]->get("title"), "Avaliação de métodos de desofuscação de palavrões";
is $entries[0]->get("author"), "Gustavo Laboreiro and Eugénio Oliveira";

my @editors = $entries[0]->names("editor");

is $editors[0]->part("last"), "Simões";
