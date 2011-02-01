# -*- cperl -*-
use strict;
use vars qw($DEBUG);
use IO::Handle;
use Test::More tests=>23;
use Encode;
use utf8;

require "t/common.pl";

use Text::BibTeX qw(:nameparts :joinmethods);
use Text::BibTeX::Name;
use Text::BibTeX::NameFormat;

$DEBUG = 1;

#setup_stderr;

# Get a name to work with (and just a quick check that the Name class
# is in working order)
my $name = new Text::BibTeX::Name
        "Charles Louis Xavier Joseph de la Vall{\\'e}e Poussin";
my @first = $name->part ('first');
my @von = $name->part ('von');
my @last = $name->part ('last');
is_deeply(\@first, [qw(Charles Louis Xavier Joseph)]);
is_deeply(\@von, [qw(de la)]);
is_deeply(\@last, ["Vall{\\'e}e", 'Poussin']);

my $name1 = new Text::BibTeX::Name
        '{John Henry} Ford';
my $format1 = new Text::BibTeX::NameFormat ('f', 1);
is ($format1->apply ($name1), 'J.');

my $name2 = new Text::BibTeX::Name
        '{John} Ford';
my $format2 = new Text::BibTeX::NameFormat ('f', 1);
is ($format2->apply ($name2), 'J.');

my $name3 = new Text::BibTeX::Name
         '{U.S. Department of Health and Human Services, National Institute of Mental Health, National Heart, Lung and Blood Institute}';
my $format3 = new Text::BibTeX::NameFormat ('l', 1);
$format3->set_text (BTN_LAST, undef, undef, undef, '.');
$format3->set_options (BTN_LAST, 1, BTJ_NOTHING, BTJ_NOTHING);
is ($format3->apply ($name3), 'U.');

my $name4 = new Text::BibTeX::Name "{\\'E}mile Zola";
my $format4 = new Text::BibTeX::NameFormat ('f', 1);
is ($format4->apply ($name4), "{\\'E}.");

my $name5 = new Text::BibTeX::Name
         'St John-Mollusc, Oliver';
my $format5 = new Text::BibTeX::NameFormat ('l', 1);
$format5->set_text (BTN_LAST, undef, undef, undef, '.');
$format5->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);
is ($format5->apply ($name5), 'S.~J.-M.');

my $name6 = new Text::BibTeX::Name
         "St John-{\\'E}mile Mollusc, Oliver";
my $format6 = new Text::BibTeX::NameFormat ('l', 1);
$format6->set_text (BTN_LAST, undef, undef, undef, '.');
$format6->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);
is ($format6->apply ($name6), "S.~J.-{\\'E}.~M.");

my $name7 = new Text::BibTeX::Name 'St {John-Mollusc}, Oliver';
my $format7 = new Text::BibTeX::NameFormat ('l', 1);
$format7->set_text (BTN_LAST, undef, undef, undef, '.');
$format7->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);
is ($format7->apply ($name7), 'S.~J.');

my $name8 = new Text::BibTeX::Name 'Šomeone Smith';
my $format8 = new Text::BibTeX::NameFormat ('f', 1);
is (decode_utf8($format8->apply ($name8)), 'Š.');

my $name9 = new Text::BibTeX::Name 'Šomeone-Šomething Smith';
my $format9 = new Text::BibTeX::NameFormat ('f', 1);
is (decode_utf8($format9->apply ($name9)), 'Š.-Š.');

my $name10 = new Text::BibTeX::Name '{Šomeone-Šomething} Smith';
my $format10 = new Text::BibTeX::NameFormat ('f', 1);
is (decode_utf8($format10->apply ($name10)), 'Š.');

my $name11 = new Text::BibTeX::Name 'Harold {K}ent-{B}arrow';
my $format11 = new Text::BibTeX::NameFormat ('l', 1);
$format11->set_text (BTN_LAST, undef, undef, undef, '.');
$format11->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);
is (decode_utf8($format11->apply ($name11)), 'K.-B.');

my $name12 = new Text::BibTeX::Name 'Mirian Neuser-Hoffman';
my $format12 = new Text::BibTeX::NameFormat ('l', 1);
$format12->set_text (BTN_LAST, undef, undef, undef, '');
$format12->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);
is ($format12->apply ($name12), 'NH');


# Start with a basic "von last, jr, first" formatter
my $format = new Text::BibTeX::NameFormat ('vljf', 1);
is ($format->apply ($name), "de~la Vall{\\'e}e~Poussin, C.~L. X.~J.");
is ($format->apply ($name), $name->format ($format));

# Tweak options: force ties between tokens of the first name
$format->set_options (BTN_FIRST, 1, BTJ_FORCETIE, BTJ_NOTHING);
is ($format->apply ($name), "de~la Vall{\\'e}e~Poussin, C.~L.~X.~J.");

# And no ties in the "von" part
$format->set_options (BTN_VON, 0, BTJ_SPACE, BTJ_SPACE);
is ($format->apply ($name), "de la Vall{\\'e}e~Poussin, C.~L.~X.~J.");

# No punctuation in the first name
$format->set_text (BTN_FIRST, undef, undef, undef, '');
is ($format->apply ($name), "de la Vall{\\'e}e~Poussin, C~L~X~J");

# And drop the first name inter-token separation entirely
$format->set_options (BTN_FIRST, 1, BTJ_NOTHING, BTJ_NOTHING);
is ($format->apply ($name), "de la Vall{\\'e}e~Poussin, CLXJ");

# Now we get silly: keep the first name tokens jammed together, but
# don't abbreviate them any more
$format->set_options (BTN_FIRST, 0, BTJ_NOTHING, BTJ_NOTHING);
is ($format->apply ($name),
    "de la Vall{\\'e}e~Poussin, CharlesLouisXavierJoseph");

# OK, but spaces back in to the first name
$format->set_options (BTN_FIRST, 0, BTJ_SPACE, BTJ_NOTHING);
is ($format->apply ($name),
    "de la Vall{\\'e}e~Poussin, Charles Louis Xavier Joseph");
